class_name OrbitCamera
extends Camera3D
## Caméra du bateau, avec deux vues (touche V) :
## - extérieure : tourne autour du bateau (clic + glisser, molette pour le zoom,
##   C pour suivre le cap ou non) ;
## - cockpit : derrière le barreur, un peu au-dessus de sa tête. Elle suit le bateau et
##   la moitié de sa gîte. Clic + glisser pour regarder autour, molette pour avancer
##   ou reculer.
## Dans les deux vues, J / L regardent par le travers bâbord / tribord ; même touche
## pour revenir.

enum Mode { EXTERIOR, COCKPIT }

@export var target: Boat
@export var distance := 16.0
@export var min_distance := 6.0
@export var max_distance := 60.0
@export var pitch_deg := -16.0
## Si vrai, la caméra extérieure se replace doucement derrière le bateau.
@export var follow_heading := true
@export var exterior_fov := 60.0
@export var cockpit_fov := 70.0
## Position de l'œil en vue cockpit (unités du modèle de 6 m : x tribord, y haut, z arrière).
@export var cockpit_eye := Vector3(0.0, 2.5, 3.4)

var mode := Mode.EXTERIOR
## Vue de travers : 0 = devant, -1 = regarde bâbord, +1 = regarde tribord.
var beam_side := 0

var _yaw_offset := 0.0
var _base_yaw := 0.0
var _beam_angle := 0.0
var _cockpit_yaw := 0.0
var _cockpit_pitch := -8.0
var _cockpit_back := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target != null and target.sim != null:
		_base_yaw = target.sim.heading


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_LEFT)):
		if mode == Mode.COCKPIT:
			_cockpit_yaw = clampf(_cockpit_yaw - event.relative.x * 0.005, -deg_to_rad(150.0), deg_to_rad(150.0))
			_cockpit_pitch = clampf(_cockpit_pitch - event.relative.y * 0.2, -45.0, 20.0)
		else:
			_yaw_offset -= event.relative.x * 0.005
			pitch_deg = clampf(pitch_deg - event.relative.y * 0.25, -80.0, -3.0)
	elif event is InputEventMouseButton and event.pressed:
		var closer: bool = event.button_index == MOUSE_BUTTON_WHEEL_UP
		var farther: bool = event.button_index == MOUSE_BUTTON_WHEEL_DOWN
		if mode == Mode.COCKPIT and (closer or farther):
			_cockpit_back = clampf(_cockpit_back + (-0.3 if closer else 0.3), -1.5, 2.5)
		elif closer:
			distance = maxf(min_distance, distance * 0.9)
		elif farther:
			distance = minf(max_distance, distance * 1.1)
	elif event.is_action_pressed("camera_mode"):
		mode = Mode.COCKPIT if mode == Mode.EXTERIOR else Mode.EXTERIOR
		_cockpit_yaw = 0.0
	elif event.is_action_pressed("camera_toggle"):
		follow_heading = not follow_heading
	elif event.is_action_pressed("look_port"):
		_toggle_beam(-1)
	elif event.is_action_pressed("look_starboard"):
		_toggle_beam(1)


## Relèvement (degrés compas) de la direction regardée.
func view_bearing_deg() -> float:
	var f := -global_basis.z
	return fposmod(rad_to_deg(atan2(f.x, -f.z)), 360.0)


func _toggle_beam(side: int) -> void:
	beam_side = 0 if beam_side == side else side
	_yaw_offset = 0.0
	_cockpit_yaw = 0.0


func _process(delta: float) -> void:
	if target == null or target.sim == null:
		return
	# Regarder à bâbord = tourner la vue vers la gauche (angle positif).
	_beam_angle = lerp_angle(_beam_angle, -beam_side * PI * 0.5, 1.0 - exp(-6.0 * delta))
	if mode == Mode.COCKPIT:
		_update_cockpit()
	else:
		_update_exterior(delta)


func _update_exterior(delta: float) -> void:
	fov = exterior_fov
	if beam_side != 0:
		# Vue de travers : on colle au cap pour lire un relèvement exact.
		_base_yaw = lerp_angle(_base_yaw, target.sim.heading, 1.0 - exp(-6.0 * delta))
	elif follow_heading:
		_base_yaw = lerp_angle(_base_yaw, target.sim.heading, 1.0 - exp(-1.2 * delta))
	var k := target.model_scale()
	var focus := target.get_global_transform_interpolated().origin + Vector3(0.0, 2.5 * k, 0.0)
	var orbit := Basis(Vector3.UP, _base_yaw + _beam_angle + _yaw_offset) * Basis(Vector3.RIGHT, deg_to_rad(pitch_deg))
	global_position = focus + orbit * Vector3(0.0, 0.0, distance * k)
	look_at(focus)


func _update_cockpit() -> void:
	fov = cockpit_fov
	var boat_xf := target.get_global_transform_interpolated()
	var k := target.model_scale()
	# Cap tiré du transform interpolé (fluide) ; la caméra ne prend que la moitié de la
	# gîte et ignore le tangage, pour ne pas donner le mal de mer.
	var heading := atan2(boat_xf.basis.z.x, boat_xf.basis.z.z)
	var frame := Basis.from_euler(Vector3(0.0, heading, -target.sim.heel * 0.5))
	var eye := cockpit_eye + Vector3(0.0, 0.0, _cockpit_back)
	global_position = boat_xf.origin + frame * (eye * k)
	global_basis = frame * Basis(Vector3.UP, _cockpit_yaw + _beam_angle) \
		* Basis(Vector3.RIGHT, deg_to_rad(_cockpit_pitch))
	_base_yaw = heading  # retour en vue extérieure sans saut
