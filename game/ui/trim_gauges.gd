extends Control
## Jauges des écoutes et de la barre, avec l'état des voiles lu sur les penons.

const TRIM_TEXT := {
	BoatSim.Trim.LUFFING: ["faseye : borde", Color(1.0, 0.75, 0.3)],
	BoatSim.Trim.GOOD: ["bien réglée", Color(0.5, 1.0, 0.55)],
	BoatSim.Trim.STALLED: ["trop bordée : choque", Color(1.0, 0.45, 0.4)],
	BoatSim.Trim.DRAG: ["choquée au portant", Color(0.5, 1.0, 0.55)],
	BoatSim.Trim.BACKED: ["à contre !", Color(1.0, 0.4, 0.4)],
	BoatSim.Trim.BLANKETED: ["déventé par la GV", Color(0.75, 0.75, 0.75)],
}

var boat: Boat
var _jib_switches := 0
var _flash_until := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(410, 112)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if boat == null or boat.sim == null:
		return
	var sim := boat.sim
	var font := ThemeDB.fallback_font
	var jib_label := "Foc (%s)" % ("tribord" if sim.jib_side > 0.0 else "bâbord")
	# L'étiquette du foc s'allume brièvement quand il change de bord.
	var now := Time.get_ticks_msec() / 1000.0
	if sim.jib_switches != _jib_switches:
		_jib_switches = sim.jib_switches
		_flash_until = now + 0.8
	var jib_color := Color(1.0, 0.85, 0.3) if now < _flash_until else Color.WHITE
	_sheet_row(font, 8.0, "Grand-voile", sim.main_sheet, sim.main_trim())
	_sheet_row(font, 44.0, jib_label, sim.jib_sheet, sim.jib_trim(), jib_color)

	# Barre : centrée, déviation vers la gauche ou la droite
	var y := 82.0
	draw_string(font, Vector2(0, y + 13), "Barre", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	var bar := Rect2(100, y, 150, 16)
	draw_rect(bar, Color(1, 1, 1, 0.15))
	var mid := bar.position.x + bar.size.x * 0.5
	var w := sim.rudder * bar.size.x * 0.5
	draw_rect(Rect2(minf(mid, mid + w), y, absf(w), 16), Color(1.0, 0.9, 0.3, 0.9))
	draw_line(Vector2(mid, y - 2), Vector2(mid, y + 18), Color.WHITE, 1.0)


func _sheet_row(font: Font, y: float, label: String, sheet: float, trim: BoatSim.Trim,
		label_color: Color = Color.WHITE) -> void:
	draw_string(font, Vector2(0, y + 13), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, label_color)
	var bar := Rect2(100, y, 150, 16)
	draw_rect(bar, Color(1, 1, 1, 0.15))
	# La jauge grandit quand on choque.
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * sheet, bar.size.y)), Color(0.55, 0.8, 1.0, 0.9))
	draw_string(font, Vector2(bar.position.x + 2, y + 30), "bordée", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(1, 1, 1, 0.5))
	draw_string(font, Vector2(bar.end.x - 48, y + 30), "choquée", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(1, 1, 1, 0.5))
	var info: Array = TRIM_TEXT[trim]
	draw_string(font, Vector2(260, y + 13), info[0], HORIZONTAL_ALIGNMENT_LEFT, 150, 13, info[1])
