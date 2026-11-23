class_name BoatSim
extends RefCounted
## Simulation d'un voilier dans le plan horizontal (cavalement, embardée, lacet) + gîte.
##
## Aucune dépendance aux nœuds : la scène du bateau appelle `step()` à chaque pas
## physique et lit l'état pour l'affichage. Conventions d'axes et de signes :
## docs/modele-voile.md.

const RHO_AIR := 1.225
const RHO_WATER := 1025.0
const GRAVITY := 9.81
const SUBSTEPS := 2

## État de réglage d'une voile, tel que le montreraient les penons.
enum Trim { LUFFING, GOOD, STALLED, DRAG, BACKED, BLANKETED }

var p: BoatParams

# --- État (monde 2D : x = X Godot, y = Z Godot) ---
var position := Vector2.ZERO
## Cap = rotation.y de Godot (rad). Positif = tourné vers bâbord.
var heading := 0.0
## Vitesse vers l'avant (m/s), repère bateau.
var u := 0.0
## Vitesse vers tribord (m/s), repère bateau.
var v := 0.0
## Vitesse de lacet (rad/s), positive = vers bâbord.
var yaw_rate := 0.0
## Gîte (rad), positive = sur tribord.
var heel := 0.0
var heel_rate := 0.0

# --- Commandes ---
## Écoutes : 0 = bordée à fond, 1 = choquée à fond.
var main_sheet := 0.5
var jib_sheet := 0.5
## Écoute de foc en service : +1 tribord, -1 bâbord.
var jib_side := 1.0
## Barre : -1..1, positif = le bateau vire vers tribord.
var rudder := 0.0

## Outils : cap bloqué (polaire, mesures d'équilibre).
var lock_heading := false

# --- Sorties ---
## Angle de bôme / de foc (rad), positif = vers tribord.
var main_angle := 0.0
var jib_angle := 0.0
## Incidence des voiles (rad).
var main_alpha := 0.0
var jib_alpha := 0.0
## Angle que prendrait une voile libre, en drapeau (rad) ; vaut -AWA.
var free_angle := 0.0
var true_wind := Vector2.ZERO
var true_wind_body := Vector2.ZERO
## Vitesse de l'air vue du bateau, repère bateau (avant, tribord).
var apparent_wind := Vector2.ZERO
var yaw_torque := 0.0
## Forces du dernier sous-pas : nom -> [point (repère bateau), force (repère bateau)].
var forces: Dictionary = {}


func _init(params: BoatParams = null) -> void:
	p = params if params != null else BoatParams.new()


func reset(pos: Vector2 = Vector2.ZERO, new_heading: float = 0.0) -> void:
	position = pos
	heading = new_heading
	u = 0.0
	v = 0.0
	yaw_rate = 0.0
	heel = 0.0
	heel_rate = 0.0


# --- Lecture de l'état ---

func forward() -> Vector2:
	return Vector2(-sin(heading), -cos(heading))


func right() -> Vector2:
	return Vector2(cos(heading), -sin(heading))


## Vitesse dans le monde 2D.
func velocity() -> Vector2:
	return forward() * u + right() * v


func speed() -> float:
	return Vector2(u, v).length()


## Angle du vent apparent (rad), positif = le vent vient de tribord.
func awa() -> float:
	return atan2(-apparent_wind.y, -apparent_wind.x)


## Angle du vent réel (rad), positif = le vent vient de tribord.
func twa() -> float:
	return atan2(-true_wind_body.y, -true_wind_body.x)


## Cap compas (degrés, 0 = nord, 90 = est).
func bearing_deg() -> float:
	return fposmod(rad_to_deg(-heading), 360.0)


func rudder_angle() -> float:
	return rudder * deg_to_rad(p.rudder_max_deg)


func jib_is_backed() -> bool:
	return absf(free_angle) > deg_to_rad(3.0) and signf(free_angle) == -jib_side \
		and signf(jib_angle) == jib_side and absf(jib_angle) > deg_to_rad(1.0)


func main_trim() -> Trim:
	return _trim(main_alpha, main_angle, p.main_max_deg)


func jib_trim() -> Trim:
	if jib_is_backed():
		return Trim.BACKED
	if absf(free_angle) > deg_to_rad(140.0):
		return Trim.BLANKETED
	return _trim(jib_alpha, jib_angle, p.jib_max_deg)


# --- Simulation ---

## Avance la simulation de `dt` secondes dans le vent réel `wind` (m/s, monde 2D).
func step(dt: float, wind: Vector2) -> void:
	true_wind = wind
	var h := dt / SUBSTEPS
	for i in SUBSTEPS:
		_substep(h)


func _substep(dt: float) -> void:
	var f := forward()
	var r := right()
	true_wind_body = Vector2(true_wind.dot(f), true_wind.dot(r))
	apparent_wind = true_wind_body - Vector2(u, v)
	var aws := apparent_wind.length()
	var flow := apparent_wind / aws if aws > 1e-4 else Vector2(-1.0, 0.0)
	free_angle = atan2(flow.y, -flow.x)
	forces.clear()

	_update_sail_angles(aws, dt)

	# --- Voiles et fardage ---
	var q_air := 0.5 * RHO_AIR * aws * aws
	var heel_eff := pow(cos(heel), 2.0)
	var ce_y := p.ce_height * sin(heel)
	var stall := deg_to_rad(p.sail_stall_deg)

	var main_chord := Vector2(-cos(main_angle), sin(main_angle))
	main_alpha = Foil.incidence(flow, main_chord)
	var cm := _sail_coefficients(main_alpha, stall)
	_add("main", Vector2(p.mast_x, ce_y) + main_chord * (p.boom_length * 0.35),
		(Foil.lift_direction(flow, main_chord) * cm.x + flow * cm.y) * (q_air * p.main_area * heel_eff))

	var jib_chord := Vector2(-cos(jib_angle), sin(jib_angle))
	jib_alpha = Foil.incidence(flow, jib_chord)
	var cj := _sail_coefficients(jib_alpha, stall)
	# Au portant, la grand-voile dévente le foc.
	var shadow := 1.0 - 0.8 * smoothstep(deg_to_rad(130.0), deg_to_rad(170.0), absf(free_angle))
	_add("jib", Vector2(p.jib_tack_x, ce_y * 0.8) + jib_chord * (p.jib_foot * 0.35),
		(Foil.lift_direction(flow, jib_chord) * cj.x + flow * cj.y) * (q_air * p.jib_area * heel_eff * shadow))

	_add("windage", Vector2(0.3, ce_y * 0.4), flow * (q_air * p.windage_area))

	# --- Carène, quille, safran ---
	var cos_heel := cos(heel)
	_add("keel", Vector2(p.keel_x, 0.0), _water_foil(
		Vector2(u, v - yaw_rate * p.keel_x), Vector2(-1.0, 0.0), p.keel_area * cos_heel,
		p.keel_cl_max, p.keel_stall_deg, p.keel_cd0, p.keel_k_induced))

	var delta := rudder_angle()
	_add("rudder", Vector2(p.rudder_x, 0.0), _water_foil(
		Vector2(u, v - yaw_rate * p.rudder_x), Vector2(-cos(delta), sin(delta)), p.rudder_area * cos_heel,
		p.rudder_cl_max, p.rudder_stall_deg, p.rudder_cd0, p.rudder_k_induced))

	var ratio := absf(u) / p.hull_speed
	var heel_drag := 1.0 + 0.5 * pow(sin(heel), 2.0)
	var hull_u := -signf(u) * p.hull_drag * u * u * (1.0 + p.wave_drag * pow(ratio, 4.0)) * heel_drag
	var hull_v := -p.hull_side_linear * v - p.hull_side_quad * v * absf(v)
	_add("hull", Vector2.ZERO, Vector2(hull_u, hull_v))

	# --- Somme des efforts ---
	var total := Vector2.ZERO
	var tau := 0.0
	for key: String in forces:
		var pt: Vector2 = forces[key][0]
		var fo: Vector2 = forces[key][1]
		total += fo
		tau += -pt.x * fo.y + pt.y * fo.x
	# Carène gîtée : le bateau devient ardent (veut lofer).
	tau += p.heel_helm * heel * u * absf(u)
	tau -= (p.yaw_damping_linear + p.yaw_damping_speed * absf(u)) * yaw_rate \
		+ p.yaw_damping_quad * yaw_rate * absf(yaw_rate)
	yaw_torque = tau

	# --- Intégration (repère bateau, avec les termes dus à la rotation) ---
	var mu := p.mass * (1.0 + p.added_mass_surge)
	var mv := p.mass * (1.0 + p.added_mass_sway)
	u += (total.x / mu - yaw_rate * v) * dt
	v += (total.y / mv + yaw_rate * u) * dt
	if lock_heading:
		yaw_rate = 0.0
	else:
		yaw_rate += tau / p.yaw_inertia * dt
		heading = wrapf(heading + yaw_rate * dt, -PI, PI)
	position += (f * u + r * v) * dt

	# --- Gîte ---
	var lateral_sail: float = forces["main"][1].y + forces["jib"][1].y + forces["windage"][1].y
	var m_heel := lateral_sail * p.ce_height * cos(heel)
	var m_right := p.mass * GRAVITY * p.metacentric_height * sin(heel)
	heel_rate += (m_heel - m_right - p.roll_damping * heel_rate) / p.roll_inertia * dt
	heel = clampf(heel + heel_rate * dt, -1.3, 1.3)


## Les voiles prennent l'angle du drapeau, bornées par leur écoute, à vitesse finie.
func _update_sail_angles(aws: float, dt: float) -> void:
	var main_limit := deg_to_rad(lerpf(p.main_min_deg, p.main_max_deg, main_sheet))
	var main_target := clampf(_flag_for_side(free_angle, signf(main_angle)), -main_limit, main_limit)
	main_angle = _swing(main_angle, main_target, aws, dt)

	if p.auto_jib:
		var auto_side := signf(_flag_for_side(free_angle, signf(jib_angle)))
		if auto_side != 0.0:
			jib_side = auto_side
	var side := jib_side
	var jib_flag := _flag_for_side(free_angle, side)
	var jib_target: float
	if signf(jib_flag) == side or jib_flag == 0.0:
		var jib_limit := deg_to_rad(lerpf(p.jib_min_deg, p.jib_max_deg, jib_sheet))
		jib_target = side * minf(absf(jib_flag), jib_limit)
	else:
		# Le vent pousse le foc vers l'autre bord : l'écoute en service le retient.
		# Bordée, elle le garde au vent (foc à contre) ; choquée, elle le laisse passer.
		var cross := 0.35
		var held_deg: float
		if jib_sheet < cross:
			held_deg = p.jib_min_deg * (1.0 - jib_sheet / cross)
		else:
			held_deg = -p.jib_max_deg * (jib_sheet - cross) / (1.0 - cross)
		var held := side * deg_to_rad(held_deg)
		jib_target = held if side * held > side * jib_flag else jib_flag
	jib_angle = _swing(jib_angle, jib_target, aws, dt)


## Angle du drapeau vu depuis le bord `side` : tant que le vent n'est pas assez
## « sous la bôme », la voile reste de son bord (pas d'empannage au moindre écart).
func _flag_for_side(flag: float, side: float) -> float:
	if side == 0.0 or signf(flag) == side:
		return flag
	if absf(flag) > PI - deg_to_rad(p.by_the_lee_deg):
		return flag + side * TAU
	return flag


## Coefficients d'une voile ; une voile qui faseye bat au vent et freine.
func _sail_coefficients(alpha: float, stall: float) -> Vector2:
	var c := Foil.coefficients(alpha, p.sail_cl_max, stall, p.sail_cd0, p.sail_k_induced)
	c.y += p.sail_flutter_cd * (1.0 - smoothstep(0.0, deg_to_rad(8.0), alpha))
	return c


func _swing(current: float, target: float, aws: float, dt: float) -> float:
	return move_toward(current, target, (1.5 + aws * 0.8) * dt)


func _water_foil(vel: Vector2, chord: Vector2, area: float, cl_max: float, stall_deg: float,
		cd0: float, k_induced: float) -> Vector2:
	var s := vel.length()
	if s < 1e-4:
		return Vector2.ZERO
	var w := -vel / s
	var c := Foil.coefficients(Foil.incidence(w, chord), cl_max, deg_to_rad(stall_deg), cd0, k_induced, true)
	return (Foil.lift_direction(w, chord) * c.x + w * c.y) * (0.5 * RHO_WATER * s * s * area)


func _add(key: String, point: Vector2, force: Vector2) -> void:
	forces[key] = [point, force]


func _trim(alpha: float, angle: float, max_deg: float) -> Trim:
	if alpha < deg_to_rad(6.0):
		return Trim.LUFFING
	if alpha > deg_to_rad(p.sail_stall_deg + 8.0):
		if absf(angle) > deg_to_rad(max_deg - 3.0):
			return Trim.DRAG
		return Trim.STALLED
	return Trim.GOOD
