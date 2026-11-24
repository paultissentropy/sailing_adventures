extends SceneTree
## Banc d'essai : un pilote automatique exécute des manœuvres types sur chaque bateau et
## compare les mesures à des fourchettes de référence (docs/references-bateaux.md).
## Lancement : tools/bench.sh. Arguments après `--` : chemin du bulletin Markdown.
##
## Vent du nord, 10 nœuds, sauf mention contraire.

const DT := 1.0 / 60.0
const KNOT := 0.514444
const PRESETS := ["res://boats/quillard_6m.tres", "res://boats/croiseur_9m.tres"]
## Barre utilisée pour virer : franche mais pas à fond (à fond, le safran freine).
const TACK_RUDDER := 0.7

## Fourchettes de référence : ordres de grandeur pour ce type de bateau, sans spi.
## [mini, maxi, unité]. Garder synchronisé avec docs/references-bateaux.md.
const REFERENCES := {
	"Quillard 6 m": {
		"pres": [4.0, 5.5, "nœuds"],
		"travers": [4.8, 6.0, "nœuds"],
		"arriere": [3.5, 5.0, "nœuds"],
		"angle_remontee": [40.0, 48.0, "°"],
		"rotation": [10.0, 25.0, "°/s"],
		"virement_duree": [4.0, 8.0, "s"],
		"virement_perte": [25.0, 55.0, "%"],
		"virement_reprise": [3.0, 12.0, "s"],
		"arret": [1.5, 4.0, "longueurs"],
		"depart": [5.0, 15.0, "s"],
		"gite_10": [8.0, 18.0, "°"],
		"gite_20": [20.0, 35.0, "°"],
		"empannage_controle": [10.0, 50.0, "°"],
		"empannage_non_controle": [120.0, 175.0, "°"],
	},
	"Croiseur 9 m": {
		"pres": [5.0, 6.0, "nœuds"],
		"travers": [5.8, 7.0, "nœuds"],
		"arriere": [4.0, 5.5, "nœuds"],
		"angle_remontee": [40.0, 48.0, "°"],
		"rotation": [6.0, 15.0, "°/s"],
		"virement_duree": [7.0, 15.0, "s"],
		"virement_perte": [25.0, 55.0, "%"],
		"virement_reprise": [5.0, 20.0, "s"],
		"arret": [2.5, 5.0, "longueurs"],
		"depart": [10.0, 30.0, "s"],
		"gite_10": [10.0, 18.0, "°"],
		"gite_20": [20.0, 30.0, "°"],
		"empannage_controle": [10.0, 50.0, "°"],
		"empannage_non_controle": [120.0, 175.0, "°"],
	},
}

const LABELS := {
	"pres": "Vitesse au près (50° du vent)",
	"travers": "Vitesse au travers",
	"arriere": "Vitesse au vent arrière",
	"angle_remontee": "Meilleur angle de remontée (VMG)",
	"rotation": "Rotation barre à fond, au travers",
	"virement_duree": "Durée du virement (près → près, barre à 70 %)",
	"virement_perte": "Perte de vitesse pendant le virement",
	"virement_reprise": "Temps pour retrouver 90 % de la vitesse",
	"arret": "Arrêt bout au vent (erre)",
	"depart": "Départ arrêté au travers (90 % de la vitesse)",
	"gite_10": "Gîte au près, 10 nœuds",
	"gite_20": "Gîte au près, 20 nœuds (voiles bordées)",
	"empannage_controle": "Empannage GV bordée : course de la bôme",
	"empannage_non_controle": "Empannage GV choquée : course de la bôme",
}

var _params: BoatParams


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "banc-essai.md"
	var md := PackedStringArray([
		"# Banc d'essai",
		"",
		"Généré par `tools/bench.sh` (ne pas modifier à la main). Un pilote automatique",
		"exécute les manœuvres ; chaque mesure est comparée à une fourchette de référence",
		"([references-bateaux.md](references-bateaux.md)). ✓ : dans la fourchette.",
		"⚠ : en dehors, à examiner (ce n'est pas forcément un défaut : le jeu privilégie la",
		"jouabilité).",
		"",
		"Vent du nord, 10 nœuds sauf mention contraire. Mode simplifié actif.",
	])
	for preset: String in PRESETS:
		_params = load(preset)
		var results := _measure()
		md.append_array(_report(results))
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_string("\n".join(md) + "\n")
	file.close()
	print("\nBulletin écrit dans ", out_path)
	quit()


func _measure() -> Dictionary:
	var r := {}
	var pres := _steady(50.0, 10.0)
	r["pres"] = pres.u / KNOT
	r["travers"] = _steady(90.0, 10.0).u / KNOT
	r["arriere"] = _steady(180.0, 10.0).u / KNOT
	r["gite_10"] = rad_to_deg(absf(pres.heel))
	r["gite_20"] = rad_to_deg(absf(_steady(50.0, 20.0).heel))

	var best_twa := 0.0
	var best_vmg := -INF
	for twa in range(34, 62, 2):
		var b := _steady(float(twa), 10.0)
		var vmg := b.u * cos(deg_to_rad(twa))
		if vmg > best_vmg:
			best_vmg = vmg
			best_twa = twa
	r["angle_remontee"] = best_twa

	r["rotation"] = _turn_rate()
	var tack := _tack()
	r["virement_duree"] = tack[0]
	r["virement_perte"] = tack[1]
	r["virement_reprise"] = tack[2]
	r["arret"] = _stop_distance() / _params.length
	r["depart"] = _start_time(r["travers"] * KNOT)
	r["empannage_controle"] = _gybe(0.1)
	r["empannage_non_controle"] = _gybe(1.0)
	return r


func _report(r: Dictionary) -> PackedStringArray:
	var refs: Dictionary = REFERENCES[_params.display_name]
	var lines := PackedStringArray(["", "## %s" % _params.display_name, "",
		"| Mesure | Valeur | Référence | Verdict |", "|---|---|---|---|"])
	print("\n" + _params.display_name)
	for key: String in LABELS:
		var ref: Array = refs[key]
		var value: float = r[key]
		var ok: bool = value >= ref[0] and value <= ref[1]
		var unit: String = ref[2]
		lines.append("| %s | %.1f %s | %s–%s %s | %s |" % [LABELS[key], value, unit,
			_num(ref[0]), _num(ref[1]), unit, "✓" if ok else "⚠"])
		print("  %s %-48s %6.1f %s  (réf. %s–%s)" % ["✓" if ok else "⚠", LABELS[key], value, unit,
			_num(ref[0]), _num(ref[1])])
	return lines


func _num(x: float) -> String:
	return ("%.0f" % x) if is_equal_approx(x, roundf(x)) else ("%.1f" % x)


# --- Manœuvres ---

## Bateau stabilisé, cap bloqué à `twa_deg` du vent (tribord amures).
func _steady(twa_deg: float, knots: float) -> BoatSim:
	var b := _boat(-twa_deg, 1.0)
	b.lock_heading = true
	_sail(b, _wind(knots), 50.0)
	return b


## Vitesse de rotation moyenne entre 1 et 3 s, barre à fond, au travers.
func _turn_rate() -> float:
	var b := _steady(90.0, 10.0)
	b.lock_heading = false
	b.rudder = 1.0
	_sail(b, _wind(10.0), 1.0)
	var h0 := b.heading
	_sail(b, _wind(10.0), 2.0)
	return absf(rad_to_deg(wrapf(b.heading - h0, -PI, PI))) / 2.0


## Virement près → près (tribord amures vers bâbord amures).
## Retourne [durée (s), perte de vitesse (%), temps de reprise à 90 % (s)].
func _tack() -> Array:
	var b := _steady(50.0, 10.0)
	b.lock_heading = false
	var u0 := b.u
	var min_u := u0
	var t := 0.0
	var duration := -1.0
	var recovery := -1.0
	b.rudder = TACK_RUDDER
	while t < 40.0:
		if int(t / DT) % 30 == 0:
			_autotrim(b)
		b.step(DT, _wind(10.0))
		t += DT
		min_u = minf(min_u, b.u)
		if duration < 0.0 and b.twa() <= -deg_to_rad(50.0):
			duration = t
			b.rudder = 0.0
		elif duration >= 0.0 and b.u >= 0.9 * u0:
			recovery = t - duration
			break
	return [duration, (1.0 - min_u / u0) * 100.0, recovery if recovery >= 0.0 else 99.0]


## Distance parcourue sur l'erre en mettant le bateau face au vent depuis le près.
func _stop_distance() -> float:
	var b := _steady(50.0, 10.0)
	b.heading = 0.0
	var distance := 0.0
	for i in int(60.0 / DT):
		b.step(DT, _wind(10.0))
		if b.u <= 0.0:
			break
		distance += b.u * DT
	return distance


## Temps pour atteindre 90 % de la vitesse stabilisée, départ arrêté au travers.
func _start_time(target_u: float) -> float:
	var b := _boat(-90.0, 0.0)
	b.lock_heading = true
	var t := 0.0
	while t < 120.0:
		if int(t / DT) % 30 == 0:
			_autotrim(b)
		b.step(DT, _wind(10.0))
		t += DT
		if b.u >= 0.9 * target_u:
			return t
	return t


## Empannage du grand largue (150°) au grand largue de l'autre bord, écoute de GV
## tenue à `main_sheet`. Retourne la course de la bôme (°) pendant le passage.
func _gybe(main_sheet: float) -> float:
	var b := _boat(150.0, 0.0)  # vent de bâbord, bôme à tribord
	b.lock_heading = true
	_sail(b, _wind(10.0), 30.0)
	b.lock_heading = false
	b.main_sheet = main_sheet
	_run(b, _wind(10.0), 2.0)
	var start := b.main_angle
	b.rudder = 1.0  # abattre puis passer le vent arrière (cap 150 → 210)
	var extreme := start
	for i in int(20.0 / DT):
		b.step(DT, _wind(10.0))
		if signf(b.main_angle) != signf(start):
			extreme = b.main_angle if absf(b.main_angle) > absf(extreme) or signf(extreme) == signf(start) \
				else extreme
		if b.bearing_deg() >= 210.0:
			b.rudder = 0.0
	return rad_to_deg(absf(start - extreme))


# --- Outils ---

func _boat(bearing: float, speed: float) -> BoatSim:
	var b := BoatSim.new(_params.duplicate())
	b.reset(Vector2.ZERO, deg_to_rad(-bearing))
	b.u = speed
	return b


func _wind(knots: float) -> Vector2:
	return WindField.flow_direction(0.0) * knots * KNOT


func _run(b: BoatSim, wind: Vector2, seconds: float) -> void:
	for i in int(seconds / DT):
		b.step(DT, wind)


func _sail(b: BoatSim, wind: Vector2, seconds: float) -> void:
	for i in int(seconds / DT):
		if i % 30 == 0:
			_autotrim(b)
		b.step(DT, wind)


## Réglage « à la main » : voiles ouvertes à environ 20° de l'écoulement.
func _autotrim(b: BoatSim) -> void:
	var target := maxf(rad_to_deg(absf(b.awa())) - 20.0, 0.0)
	b.main_sheet = clampf((target - b.p.main_min_deg) / (b.p.main_max_deg - b.p.main_min_deg), 0.0, 1.0)
	b.jib_sheet = clampf((target - b.p.jib_min_deg) / (b.p.jib_max_deg - b.p.jib_min_deg), 0.0, 1.0)
