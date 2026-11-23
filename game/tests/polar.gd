extends SceneTree
## Polaire de vitesse du bateau : pour chaque force de vent et chaque angle au vent réel,
## vitesse stabilisée avec les écoutes optimisées. Lancement : tools/polar.sh
##
## Arguments (après `--`) : chemin du CSV de sortie.

const DT := 1.0 / 60.0
const KNOT := 0.514444
const WINDS_KN: Array[float] = [6.0, 10.0, 15.0, 20.0]
const SETTLE_S := 12.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "polar.csv"
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		printerr("Impossible d'écrire ", out_path)
		quit(1)
		return
	file.store_line("wind_kn,twa_deg,speed_kn,vmg_kn,main_sheet,jib_sheet,heel_deg,leeway_deg")
	for wind_kn in WINDS_KN:
		print("\nVent %d nœuds" % wind_kn)
		print("  TWA  vitesse   VMG   GV   foc  gîte  dérive")
		for twa_deg in range(30, 181, 10):
			var best := _optimize(float(twa_deg), wind_kn)
			var b: BoatSim = best.sim
			var spd := b.speed() / KNOT
			var vmg := b.velocity().dot(-WindField.flow_direction(0.0)) / KNOT
			var leeway := rad_to_deg(atan2(b.v, maxf(absf(b.u), 0.01)))
			print("  %3d  %5.2f  %5.2f  %4.2f  %4.2f  %4.0f°  %4.1f°" \
				% [twa_deg, spd, vmg, b.main_sheet, b.jib_sheet, rad_to_deg(absf(b.heel)), leeway])
			file.store_line("%d,%d,%.3f,%.3f,%.2f,%.2f,%.2f,%.2f" \
				% [wind_kn, twa_deg, spd, vmg, b.main_sheet, b.jib_sheet, rad_to_deg(absf(b.heel)), leeway])
	file.close()
	print("\nPolaire écrite dans ", out_path)
	quit()


## Recherche par coordonnées des meilleurs réglages d'écoutes.
func _optimize(twa_deg: float, wind_kn: float) -> Dictionary:
	var main := 0.5
	var jib := 0.5
	var best := _evaluate(twa_deg, wind_kn, main, jib)
	for pass_index in 2:
		var step := 0.1 if pass_index == 0 else 0.04
		for which in 2:
			for k in range(-5, 6):
				var m := clampf(main + (k * step if which == 0 else 0.0), 0.0, 1.0)
				var j := clampf(jib + (k * step if which == 1 else 0.0), 0.0, 1.0)
				var candidate := _evaluate(twa_deg, wind_kn, m, j)
				if candidate.sim.speed() > best.sim.speed():
					best = candidate
					main = m
					jib = j
	return best


func _evaluate(twa_deg: float, wind_kn: float, main: float, jib: float) -> Dictionary:
	var b := BoatSim.new()
	b.reset(Vector2.ZERO, deg_to_rad(twa_deg))  # vent du nord, venant de bâbord
	b.lock_heading = true
	b.u = 1.5
	b.main_sheet = main
	b.jib_sheet = jib
	b.jib_side = 1.0  # sous le vent (tribord)
	var wind := WindField.flow_direction(0.0) * wind_kn * KNOT
	for i in int(SETTLE_S / DT):
		b.step(DT, wind)
	return {"sim": b}
