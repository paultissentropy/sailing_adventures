class_name Recorder
extends Node
## Enregistreur de partie (F3) : note l'état du bateau 10 fois par seconde dans un CSV,
## pour analyser ses manœuvres avec `tools/analyse_partie.py`.
##
## Fichier : tools/out/partie-<date>.csv dans le dépôt (ou user:// si le dépôt n'est pas
## accessible, par exemple dans un jeu exporté).

const PERIOD := 0.1
const HEADER := "t,x,z,cap_deg,vitesse_kn,u,twa_deg,vent_kn,gv,foc,foc_bord,barre,gite_deg,bome_deg,bateau"

@export var boat: Boat

var recording := false
var path := ""

var _file: FileAccess
var _t := 0.0
var _timer := 0.0


func toggle() -> void:
	if recording:
		stop()
	else:
		start()


func start() -> void:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var dir := ProjectSettings.globalize_path("res://").path_join("../tools/out").simplify_path()
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		dir = ProjectSettings.globalize_path("user://")
	path = dir.path_join("partie-%s.csv" % stamp)
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		push_warning("Enregistrement impossible : %s" % path)
		return
	_file.store_line(HEADER)
	recording = true
	_t = 0.0
	_timer = 0.0
	print("Enregistrement de la partie : ", path)


func stop() -> void:
	if _file != null:
		_file.close()
		_file = null
	if recording:
		print("Enregistrement terminé : ", path)
	recording = false


func _physics_process(dt: float) -> void:
	if not recording or boat == null or boat.sim == null:
		return
	_t += dt
	_timer += dt
	if _timer < PERIOD:
		return
	_timer = 0.0
	_file.store_line(row(boat.sim, _t))


## Une ligne du CSV (aussi utilisée par game/tests/record_demo.gd).
static func row(s: BoatSim, t: float) -> String:
	return "%.2f,%.2f,%.2f,%.1f,%.2f,%.3f,%.1f,%.1f,%.3f,%.3f,%d,%.2f,%.1f,%.1f,%s" % [
		t, s.position.x, s.position.y, s.bearing_deg(), s.speed() / WindField.KNOT, s.u,
		rad_to_deg(s.twa()), s.true_wind.length() / WindField.KNOT, s.main_sheet, s.jib_sheet,
		int(s.jib_side), s.rudder, rad_to_deg(s.heel), rad_to_deg(s.main_angle), s.p.display_name]


func _exit_tree() -> void:
	stop()
