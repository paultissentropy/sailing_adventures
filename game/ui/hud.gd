class_name Hud
extends CanvasLayer
## Interface de développement : instruments, état des voiles, conseils et aide.
## F2 masque les instruments pour naviguer au ressenti (voir docs/vision.md).

const KNOT := 0.514444
const Compass := preload("res://ui/compass.gd")
const TrimGauges := preload("res://ui/trim_gauges.gd")
const BearingTape := preload("res://ui/bearing_tape.gd")

var boat: Boat
var wind: WindField
var recorder: Recorder

var _heading: Label
var _info: Label
var _hint: Label
var _help: PanelContainer
var _compass: Compass
var _gauges: TrimGauges
var _tape: BearingTape
## Éléments chiffrés masqués par F2.
var _instruments: Array[Control] = []
var _jib_switches := 0
var _jib_message_until := 0.0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["DejaVu Sans Mono", "Liberation Mono", "Menlo", "Consolas", "monospace"])

	# En haut à gauche : le cap en grand, puis les autres informations.
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	_heading = Label.new()
	_heading.add_theme_font_override("font", mono)
	_heading.add_theme_font_size_override("font_size", 34)
	left.add_child(_panel(_heading))
	_info = Label.new()
	_info.add_theme_font_override("font", mono)
	_info.add_theme_font_size_override("font_size", 15)
	left.add_child(_panel(_info))
	_place(root, left, Control.PRESET_TOP_LEFT)

	_tape = BearingTape.new()
	_place(root, _tape, Control.PRESET_CENTER_TOP)

	_compass = Compass.new()
	var compass_panel := _panel(_compass)
	_place(root, compass_panel, Control.PRESET_TOP_RIGHT)

	_gauges = TrimGauges.new()
	var gauges_panel := _panel(_gauges)
	_place(root, gauges_panel, Control.PRESET_BOTTOM_LEFT)

	var help_label := Label.new()
	help_label.text = _help_text()
	help_label.add_theme_font_override("font", mono)
	help_label.add_theme_font_size_override("font_size", 13)
	_help = _panel(help_label)
	_place(root, _help, Control.PRESET_BOTTOM_RIGHT)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(root, _hint, Control.PRESET_CENTER_TOP)
	_hint.offset_top += 100.0
	_hint.offset_bottom += 100.0

	_instruments = [left, _tape, compass_panel, gauges_panel, _hint]


func setup(new_boat: Boat, new_wind: WindField, camera: OrbitCamera, buoys: Array[Node3D]) -> void:
	boat = new_boat
	wind = new_wind
	_compass.boat = boat
	_gauges.boat = boat
	_tape.boat = boat
	_tape.camera = camera
	_tape.buoys = buoys


func toggle_help() -> void:
	_help.visible = not _help.visible


func toggle_instruments() -> void:
	for node in _instruments:
		node.visible = not node.visible


func _process(_delta: float) -> void:
	if boat == null or boat.sim == null or wind == null:
		return
	var sim := boat.sim
	var twa := rad_to_deg(sim.twa())
	var tw := sim.true_wind
	_heading.text = "CAP %03.0f°" % sim.bearing_deg()
	var lines := PackedStringArray([
		"Bateau   %s" % sim.p.display_name,
		"Vitesse  %4.1f nœuds" % (sim.speed() / KNOT),
		"Allure   %s, %s" % [_point_of_sail(absf(twa)), "tribord amures" if twa > 0.0 else "bâbord amures"],
		"Vent     %4.1f nœuds du %03.0f°" % [tw.length() / KNOT, fposmod(rad_to_deg(atan2(-tw.x, tw.y)), 360.0)],
		"Gîte     %4.0f°" % absf(rad_to_deg(sim.heel)),
	])
	if recorder != null and recorder.recording:
		lines.append("● Enregistrement (F3 pour arrêter)")
	_info.text = "\n".join(lines)
	_hint.text = _hint_text(absf(twa))


func _point_of_sail(twa: float) -> String:
	if twa < 38.0:
		return "vent debout"
	if twa < 50.0:
		return "près serré"
	if twa < 65.0:
		return "près"
	if twa < 80.0:
		return "bon plein"
	if twa < 100.0:
		return "travers"
	if twa < 135.0:
		return "largue"
	if twa < 165.0:
		return "grand largue"
	return "vent arrière"


func _hint_text(twa: float) -> String:
	var sim := boat.sim
	var now := Time.get_ticks_msec() / 1000.0
	if sim.jib_switches != _jib_switches:
		_jib_switches = sim.jib_switches
		_jib_message_until = now + 2.5
	if now < _jib_message_until:
		return "Le foc passe à %s." % ("tribord" if sim.jib_side > 0.0 else "bâbord")
	if twa < 38.0 and sim.u < 0.4:
		return "Bout au vent : le bateau n'avance plus et la barre ne répond plus."
	if absf(sim.heel) > deg_to_rad(25.0):
		return "Trop de gîte : choque la grand-voile."
	return ""


func _help_text() -> String:
	var rows := [
		["Barre", "helm_left", "helm_right"],
		["Grand-voile : border / choquer", "main_in", "main_out"],
		["Foc : border / choquer", "jib_in", "jib_out"],
		["Regarder par le travers Bd / Td", "look_port", "look_starboard"],
		["Vent : tourner", "wind_left", "wind_right"],
		["Vent : force", "wind_down", "wind_up"],
		["Changer de bateau", "boat_switch", ""],
		["Vue extérieure / cockpit", "camera_mode", ""],
		["Caméra suit le cap", "camera_toggle", ""],
		["Enregistrer la partie", "record_toggle", ""],
		["Masquer les instruments", "instruments_toggle", ""],
		["Vecteurs de debug", "debug_toggle", ""],
		["Replacer le bateau", "reset_boat", ""],
		["Cacher l'aide", "help_toggle", ""],
	]
	var lines := PackedStringArray()
	for row: Array in rows:
		var keys: String = Controls.key_label(row[1])
		if row[2] != "":
			keys += "  ·  " + Controls.key_label(row[2])
		lines.append("%-32s %s" % [row[0], keys])
	lines.append("Choquer deux fois vite : l'écoute file en grand")
	lines.append("Clic + glisser : tourner la caméra · Molette : zoom")
	return "\n".join(lines)


func _panel(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.2, 0.6)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	return panel


func _place(root: Control, node: Control, preset: Control.LayoutPreset) -> void:
	root.add_child(node)
	node.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 16)
	match preset:
		Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_RIGHT:
			node.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		Control.PRESET_CENTER_TOP:
			node.grow_horizontal = Control.GROW_DIRECTION_BOTH
	match preset:
		Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT:
			node.grow_vertical = Control.GROW_DIRECTION_BEGIN
