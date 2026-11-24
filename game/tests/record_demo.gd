extends SceneTree
## Partie de démonstration : un virement puis un empannage non contrôlé, enregistrés au
## même format que l'enregistreur du jeu (F3). Sert à vérifier tools/analyse_partie.py.
## Lancement : godot --headless --path game -s res://tests/record_demo.gd -- sortie.csv

const DT := 1.0 / 60.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "partie-demo.csv"
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_line(Recorder.HEADER)
	var b := BoatSim.new(load("res://boats/quillard_6m.tres").duplicate())
	b.reset(Vector2.ZERO, deg_to_rad(50.0))  # cap 310 : près, tribord amures
	b.u = 2.0
	var wind := WindField.flow_direction(0.0) * 10.0 * WindField.KNOT
	var t := 0.0
	var phase := 0
	while t < 90.0:
		var target := maxf(rad_to_deg(absf(b.twa())) - 20.0, 0.0)
		b.main_sheet = clampf((target - 2.0) / 83.0, 0.0, 1.0)
		b.jib_sheet = clampf((target - 10.0) / 65.0, 0.0, 1.0)
		if phase == 0 and t > 15.0:
			b.rudder = 0.7  # virement
			phase = 1
		elif phase == 1 and b.twa() < -deg_to_rad(50.0):
			b.rudder = 0.0
			phase = 2
		elif phase == 2 and t > 40.0:
			b.rudder = 0.6  # bâbord amures : on abat (vers tribord) jusqu'au grand largue
			phase = 3
		elif phase == 3 and absf(b.twa()) > deg_to_rad(150.0):
			b.rudder = 0.0
			phase = 4
		elif phase == 4 and t > 60.0:
			b.rudder = 0.6  # empannage, GV choquée
			phase = 5
		elif phase == 5 and b.twa() > 0.0 and absf(b.twa()) < deg_to_rad(150.0):
			b.rudder = 0.0
			phase = 6
		if phase >= 3:
			b.main_sheet = 1.0
		b.step(DT, wind)
		t += DT
		if int(t / DT) % 6 == 0:
			file.store_line(Recorder.row(b, t))
	file.close()
	print("Partie de démonstration écrite dans ", out_path)
	quit()
