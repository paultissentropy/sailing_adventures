extends Control
## Compas de relèvement : bande graduée qui montre le relèvement de la direction regardée.
##
## Repères : bouées (pastilles de leur couleur), origine du vent (flèche bleue),
## avant du bateau (▲) et ses deux travers (« Bd » et « Td »). On lit ainsi si une
## bouée est devant ou derrière le travers, c'est-à-dire s'il est temps de virer.

const SPAN_DEG := 70.0  # demi-largeur visible

var boat: Boat
var camera: OrbitCamera
## Bouées : nœuds 3D avec une propriété `color`.
var buoys: Array[Node3D] = []


func _ready() -> void:
	custom_minimum_size = Vector2(560, 74)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if boat == null or boat.sim == null or camera == null:
		return
	var font := ThemeDB.fallback_font
	var w := size.x
	var center := camera.view_bearing_deg()
	var band_y := 22.0
	var white := Color(1, 1, 1, 0.85)
	draw_rect(Rect2(0, band_y, w, 30), Color(0.04, 0.12, 0.2, 0.6))

	# Graduations
	var first := int(floor((center - SPAN_DEG) / 5.0)) * 5
	for deg in range(first, int(center + SPAN_DEG) + 5, 5):
		var x := _x_for(float(deg), center)
		if x < 0.0 or x > w:
			continue
		var major := deg % 30 == 0
		draw_line(Vector2(x, band_y), Vector2(x, band_y + (12.0 if major else 6.0)), white, 1.0)
		if major:
			draw_string(font, Vector2(x - 16, band_y + 26), _label(deg), HORIZONTAL_ALIGNMENT_CENTER, 32, 12, white)

	# Repères du bateau : avant et travers
	var heading := boat.sim.bearing_deg()
	_marker(font, heading, center, "▲", Color(1, 1, 1))
	_marker(font, heading - 90.0, center, "Bd", Color(1.0, 0.45, 0.4))
	_marker(font, heading + 90.0, center, "Td", Color(0.45, 1.0, 0.5))

	# Origine du vent
	var tw := boat.sim.true_wind
	if tw.length() > 0.2:
		var wind_from := rad_to_deg(atan2(-tw.x, tw.y))
		var x := _x_for(wind_from, center)
		if x >= 0.0 and x <= w:
			draw_colored_polygon(PackedVector2Array([Vector2(x, band_y + 2), Vector2(x - 7, band_y - 10),
				Vector2(x + 7, band_y - 10)]), Color(0.35, 0.6, 1.0))
			draw_string(font, Vector2(x - 20, band_y - 12), "vent", HORIZONTAL_ALIGNMENT_CENTER, 40, 11,
				Color(0.55, 0.75, 1.0))

	# Bouées
	var pos := boat.sim.position
	for buoy in buoys:
		var d := Vector2(buoy.global_position.x, buoy.global_position.z) - pos
		var x := _x_for(rad_to_deg(atan2(d.x, -d.y)), center)
		if x >= 0.0 and x <= w:
			draw_circle(Vector2(x, band_y + 15), 5.0, buoy.get("color"))
			draw_arc(Vector2(x, band_y + 15), 5.0, 0.0, TAU, 16, Color(0, 0, 0, 0.6), 1.0, true)

	# Ligne de foi et relèvement lu
	draw_line(Vector2(w * 0.5, band_y - 4), Vector2(w * 0.5, band_y + 34), Color(1.0, 0.85, 0.3), 2.0)
	draw_string(font, Vector2(w * 0.5 - 40, band_y + 50), "%03.0f°" % center, HORIZONTAL_ALIGNMENT_CENTER, 80, 15,
		Color(1.0, 0.85, 0.3))


func _x_for(bearing: float, center: float) -> float:
	return size.x * 0.5 + wrapf(bearing - center, -180.0, 180.0) / SPAN_DEG * size.x * 0.5


func _marker(font: Font, bearing: float, center: float, text: String, color: Color) -> void:
	var x := _x_for(bearing, center)
	if x < 0.0 or x > size.x:
		return
	draw_string(font, Vector2(x - 15, 14), text, HORIZONTAL_ALIGNMENT_CENTER, 30, 13, color)
	draw_line(Vector2(x, 16), Vector2(x, 52), Color(color, 0.6), 1.0)


func _label(deg: int) -> String:
	match posmod(deg, 360):
		0:
			return "N"
		90:
			return "E"
		180:
			return "S"
		270:
			return "O"
	return "%03d" % posmod(deg, 360)
