class_name Hud
extends CanvasLayer
## Interface : instruments, état des voiles, conseils et aide des touches.

const KNOT := 0.514444
const Compass := preload("res://ui/compass.gd")
const TrimGauges := preload("res://ui/trim_gauges.gd")

var boat: Boat
var wind: WindField

var _info: Label
var _hint: Label
var _help: PanelContainer
var _compass: Compass
var _gauges: TrimGauges


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["DejaVu Sans Mono", "Liberation Mono", "Menlo", "Consolas", "monospace"])

	_info = Label.new()
	_info.add_theme_font_override("font", mono)
	_info.add_theme_font_size_override("font_size", 16)
	_place(root, _panel(_info), Control.PRESET_TOP_LEFT)

	_compass = Compass.new()
	_place(root, _panel(_compass), Control.PRESET_TOP_RIGHT)

	_gauges = TrimGauges.new()
	_place(root, _panel(_gauges), Control.PRESET_BOTTOM_LEFT)

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


func setup(new_boat: Boat, new_wind: WindField) -> void:
	boat = new_boat
	wind = new_wind
	_compass.boat = boat
	_gauges.boat = boat


func toggle_help() -> void:
	_help.visible = not _help.visible


func _process(_delta: float) -> void:
	if boat == null or boat.sim == null or wind == null:
		return
	var sim := boat.sim
	var twa := rad_to_deg(sim.twa())
	var awa := rad_to_deg(sim.awa())
	var lines := PackedStringArray([
		"Vitesse   %4.1f nœuds" % (sim.speed() / KNOT),
		"Cap       %03.0f°" % sim.bearing_deg(),
		"Allure    %s, %s" % [_point_of_sail(absf(twa)), "tribord amures" if twa > 0.0 else "bâbord amures"],
		"Vent réel %4.1f nœuds du %03.0f°%s" % [sim.true_wind.length() / KNOT, wind.from_deg,
			"  (risées)" if wind.gusts_enabled else ""],
		"Vent app. %4.1f nœuds à %.0f° %s" % [sim.apparent_wind.length() / KNOT, absf(awa),
			"tribord" if awa > 0.0 else "bâbord"],
		"Gîte      %4.0f°" % absf(rad_to_deg(sim.heel)),
	])
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
	if sim.jib_trim() == BoatSim.Trim.BACKED:
		return "Foc à contre : il fait abattre. %s pour changer d'écoute de foc." % Controls.key_label("jib_switch")
	if twa < 38.0 and sim.u < 0.4:
		return "Bout au vent : le bateau n'avance plus. Abats (foc à contre, ou barre en reculant)."
	if absf(sim.heel) > deg_to_rad(25.0):
		return "Trop de gîte : choque la grand-voile ou lofe un peu."
	if sim.speed() > 0.5 and absf(sim.u) < 0.5 * sim.speed():
		return "Le bateau dérive : il faut de la vitesse pour que la quille porte."
	return ""


func _help_text() -> String:
	var rows := [
		["Barre", "helm_left", "helm_right"],
		["Grand-voile : border / choquer", "main_in", "main_out"],
		["Foc : border / choquer", "jib_in", "jib_out"],
		["Changer d'écoute de foc", "jib_switch", ""],
		["Vent : tourner", "wind_left", "wind_right"],
		["Vent : force", "wind_down", "wind_up"],
		["Risées", "gusts_toggle", ""],
		["Caméra suit le cap", "camera_toggle", ""],
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
