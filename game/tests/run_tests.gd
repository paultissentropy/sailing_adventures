extends SceneTree
## Tests de la simulation de voile, sans interface. Lancement : tools/test.sh
##
## Chaque méthode `test_*` est exécutée. Le vent vient du nord sauf mention contraire.

const DT := 1.0 / 60.0
const KNOT := 0.514444

var _passed := 0
var _failed := 0


func _initialize() -> void:
	for method in get_method_list():
		var method_name: String = method.name
		if not method_name.begins_with("test_"):
			continue
		var before := _failed
		call(method_name)
		print(("  ok     " if _failed == before else "  ÉCHEC  ") + method_name)
	print("\n%d vérifications réussies, %d échecs" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# --- Tests ---

func test_safran_inefficace_a_l_arret() -> void:
	var b := _boat(0.0)
	b.rudder = 1.0
	_run(b, Vector2.ZERO, 3.0)
	_check(absf(b.heading) < 0.01, "à l'arrêt, la barre ne doit pas faire tourner (cap %.3f rad)" % b.heading)


func test_safran_efficace_en_route() -> void:
	var b := _boat(0.0, 2.5)
	b.rudder = 1.0
	_run(b, Vector2.ZERO, 2.0)
	_check(b.heading < -0.3, "barre à droite en route : le bateau doit virer à droite (cap %.2f rad)" % b.heading)


func test_marche_arriere_inverse_le_safran() -> void:
	var b := _boat(0.0, -1.0)
	b.rudder = 1.0
	_run(b, Vector2.ZERO, 1.5)
	_check(b.heading > 0.02, "en marche arrière, l'effet de barre s'inverse (cap %.3f rad)" % b.heading)


func test_vent_debout_le_bateau_s_arrete() -> void:
	var b := _boat(0.0, 2.5)
	b.lock_heading = true
	var distance := 0.0
	for i in int(25.0 / DT):
		if i % 30 == 0:
			_autotrim(b)
		b.step(DT, _wind(10.0))
		distance += maxf(b.u, 0.0) * DT
	_check(b.u < 0.3, "face au vent, le bateau doit s'arrêter (u = %.2f m/s)" % b.u)
	_check(distance > 8.0 and distance < 18.0, "arrêt bout au vent en 8 à 18 m (%.1f m)" % distance)


func test_pas_de_propulsion_trop_pres_du_vent() -> void:
	var b := _boat(20.0)
	b.lock_heading = true
	_sail(b, _wind(10.0), 40.0)
	_check(b.u < 0.5, "à 20° du vent, le bateau n'avance pas (u = %.2f m/s, dérive %.2f m/s)" % [b.u, b.v])


func test_vitesses_selon_les_allures() -> void:
	var s50 := _steady_speed(50.0, 10.0)
	var s90 := _steady_speed(90.0, 10.0)
	var s150 := _steady_speed(150.0, 10.0)
	_check(s50 > 3.0 * KNOT, "au près (50°), au moins 3 nœuds (%.1f)" % (s50 / KNOT))
	_check(s90 > s50, "le travers est plus rapide que le près (%.1f > %.1f nœuds)" % [s90 / KNOT, s50 / KNOT])
	_check(s90 > s150, "le travers est plus rapide que le grand largue (%.1f > %.1f nœuds)" % [s90 / KNOT, s150 / KNOT])


func test_vitesse_de_carene() -> void:
	var s := _steady_speed(100.0, 25.0)
	var hull_speed := BoatParams.new().hull_speed
	_check(s < hull_speed * 1.3, "même par 25 nœuds, le bateau plafonne près de sa vitesse de carène (%.1f nœuds)" % (s / KNOT))


func test_cap_tenu_quel_que_soit_le_reglage() -> void:
	# Barre au centre, voiles déséquilibrées : le cap ne bouge pas.
	var b := _boat(-50.0, 2.0)
	var start := b.heading
	b.main_sheet = 0.0
	b.jib_sheet = 1.0
	_run(b, _wind(12.0), 10.0)
	b.main_sheet = 1.0
	b.jib_sheet = 0.0
	_run(b, _wind(12.0), 10.0)
	_check(absf(b.heading - start) < 0.001, "barre au centre, le cap est tenu (écart %.4f rad)" % (b.heading - start))


func test_pas_de_derive() -> void:
	var b := _boat(-45.0)
	_sail(b, _wind(15.0), 30.0)
	_check(b.v == 0.0, "pas de glissement latéral (v = %.3f m/s)" % b.v)


func test_foc_jamais_a_contre() -> void:
	# Arrêté presque bout au vent, foc tenu du côté d'où vient le vent :
	# en mode foc automatique, il passe tout seul sous le vent.
	var b := _boat(-10.0)
	b.jib_side = 1.0
	b.jib_angle = deg_to_rad(10.0)
	b.jib_sheet = 0.0
	_run(b, _wind(10.0), 1.0)
	_check(b.jib_trim() != BoatSim.Trim.BACKED, "le foc ne reste pas à contre")
	_check(b.jib_side == -1.0, "le foc est passé sous le vent (bâbord)")


func test_virement_propre() -> void:
	# Tribord amures au près, on vire : barre à droite (vers le vent).
	var b := _boat(-45.0)
	b.lock_heading = true
	_sail(b, _wind(10.0), 30.0)
	b.lock_heading = false
	b.rudder = 1.0
	var tacked := false
	var backed := false
	for i in int(15.0 / DT):
		b.step(DT, _wind(10.0))
		backed = backed or b.jib_trim() == BoatSim.Trim.BACKED
		if b.twa() < -deg_to_rad(45.0):
			tacked = true
			break
	_check(tacked, "le virement passe avec l'élan (angle au vent final %.0f°)" % rad_to_deg(b.twa()))
	_check(not backed, "le foc n'est jamais à contre pendant le virement")
	b.rudder = 0.0
	_sail(b, _wind(10.0), 10.0, false)
	var heading := b.heading
	_sail(b, _wind(10.0), 5.0, false)
	_check(b.jib_side == 1.0, "après le virement, le foc est sous le vent (tribord)")
	_check(b.speed() > 1.5, "après le virement, le bateau repart (%.2f m/s)" % b.speed())
	_check(absf(b.heading - heading) < 0.001, "barre au centre, le nouveau cap est tenu")


func test_double_appui_choque_en_grand() -> void:
	var s := SheetInput.new()
	_check(not s.press(10.0), "un appui seul ne choque pas en grand")
	_check(s.press(10.2), "deux appuis en 0,2 s choquent en grand")
	_check(not s.press(10.35), "un troisième appui ne compte pas comme un nouveau double")
	_check(not s.press(11.0), "deux appuis espacés de 0,65 s ne comptent pas")


func test_empannage_avec_vent_sous_la_bome() -> void:
	# Vent arrière tribord amures : bôme à bâbord.
	var b := _boat(190.0)
	b.lock_heading = true
	_sail(b, _wind(10.0), 15.0)
	_check(b.main_angle < 0.0, "vent de tribord : bôme à bâbord (%.0f°)" % rad_to_deg(b.main_angle))
	b.heading = deg_to_rad(-175.0)  # 5° « sous la bôme »
	_run(b, _wind(10.0), 3.0)
	_check(b.main_angle < 0.0, "5° sous la bôme : elle reste de son bord (%.0f°)" % rad_to_deg(b.main_angle))
	b.heading = deg_to_rad(-160.0)  # 20° sous la bôme
	_run(b, _wind(10.0), 3.0)
	_check(b.main_angle > 0.0, "20° sous la bôme : elle passe de l'autre bord (%.0f°)" % rad_to_deg(b.main_angle))


func test_la_gite_augmente_avec_le_vent() -> void:
	var light := _boat(-60.0)
	light.lock_heading = true
	_sail(light, _wind(8.0), 30.0)
	var strong := _boat(-60.0)
	strong.lock_heading = true
	_sail(strong, _wind(16.0), 30.0)
	_check(light.heel < 0.0, "vent de tribord : gîte sur bâbord (%.0f°)" % rad_to_deg(light.heel))
	_check(absf(strong.heel) > absf(light.heel) + deg_to_rad(5.0),
		"plus de vent, plus de gîte (%.0f° contre %.0f°)" % [rad_to_deg(absf(strong.heel)), rad_to_deg(absf(light.heel))])


# --- Outils ---

func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		printerr("         ✗ " + msg)


## Bateau au cap compas `bearing` (degrés), avec une vitesse initiale `speed` (m/s).
func _boat(bearing: float, speed: float = 0.0) -> BoatSim:
	var b := BoatSim.new()
	b.reset(Vector2.ZERO, deg_to_rad(-bearing))
	b.u = speed
	return b


func _wind(knots: float, from_deg: float = 0.0) -> Vector2:
	return WindField.flow_direction(deg_to_rad(from_deg)) * knots * KNOT


func _run(b: BoatSim, wind: Vector2, seconds: float) -> void:
	for i in int(seconds / DT):
		b.step(DT, wind)


## Navigue en réglant les voiles automatiquement chaque demi-seconde.
func _sail(b: BoatSim, wind: Vector2, seconds: float, move_jib: bool = true) -> void:
	for i in int(seconds / DT):
		if i % 30 == 0:
			_autotrim(b, move_jib)
		b.step(DT, wind)


## Réglage « à la main » : voiles ouvertes à environ 20° de l'écoulement, foc sous le vent.
func _autotrim(b: BoatSim, move_jib: bool = true) -> void:
	var target := maxf(rad_to_deg(absf(b.awa())) - 20.0, 0.0)
	b.main_sheet = clampf((target - b.p.main_min_deg) / (b.p.main_max_deg - b.p.main_min_deg), 0.0, 1.0)
	b.jib_sheet = clampf((target - b.p.jib_min_deg) / (b.p.jib_max_deg - b.p.jib_min_deg), 0.0, 1.0)
	if move_jib and b.awa() != 0.0:
		b.jib_side = -signf(b.awa())


## Vitesse stabilisée, cap bloqué à `twa_deg` du vent (tribord amures).
func _steady_speed(twa_deg: float, knots: float) -> float:
	var b := _boat(-twa_deg, 1.0)
	b.lock_heading = true
	_sail(b, _wind(knots), 60.0)
	return b.speed()
