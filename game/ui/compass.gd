extends Control
## Rose du vent, vue du dessus, l'avant du bateau vers le haut.
## Secteur rouge : zone vent debout (on ne peut pas y faire route).
## Flèche bleue : vent réel. Flèche cyan : vent apparent.

const NO_GO_DEG := 40.0

var boat: Boat


func _ready() -> void:
	custom_minimum_size = Vector2(210, 210)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if boat == null or boat.sim == null:
		return
	var sim := boat.sim
	var c := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 14.0
	var font := ThemeDB.fallback_font

	draw_circle(c, radius + 10.0, Color(0.05, 0.15, 0.25, 0.55))
	draw_arc(c, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.35), 1.5, true)

	# Zone vent debout autour de la direction du vent réel
	var twa := sim.twa()
	var pts := PackedVector2Array([c])
	for i in 13:
		var a := twa - deg_to_rad(NO_GO_DEG) + deg_to_rad(2.0 * NO_GO_DEG) * i / 12.0
		pts.append(c + _dir(a) * radius)
	draw_colored_polygon(pts, Color(0.95, 0.3, 0.3, 0.28))

	# Graduations tous les 30°
	for i in 12:
		var a := deg_to_rad(30.0 * i)
		draw_line(c + _dir(a) * (radius - 6.0), c + _dir(a) * radius, Color(1, 1, 1, 0.5), 1.0)

	# Bateau : coque, bôme, foc, safran
	var hull := PackedVector2Array()
	for p in [Vector2(0, -38), Vector2(13, -10), Vector2(12, 22), Vector2(-12, 22), Vector2(-13, -10)]:
		hull.append(c + p)
	draw_colored_polygon(hull, Color(0.97, 0.95, 0.9, 0.9))
	var mast := c + Vector2(0, -4)
	draw_line(mast, mast + _sail_dir(sim.main_angle) * 30.0, Color(0.9, 0.3, 0.25), 3.0, true)
	var tack := c + Vector2(0, -32)
	draw_line(tack, tack + _sail_dir(sim.jib_angle) * 24.0, Color(1.0, 0.65, 0.2), 2.5, true)
	var stern := c + Vector2(0, 22)
	draw_line(stern, stern + _sail_dir(sim.rudder_angle()) * 10.0, Color(0.2, 0.2, 0.25), 3.0, true)

	# Vent réel et apparent : flèches qui pointent vers le centre
	_wind_arrow(c, radius, twa, sim.true_wind.length(), Color(0.35, 0.6, 1.0), 4.0)
	_wind_arrow(c, radius * 0.8, sim.awa(), sim.apparent_wind.length(), Color(0.4, 1.0, 1.0), 2.5)

	# Nord, vu depuis l'avant du bateau
	draw_string(font, c + _dir(-deg_to_rad(sim.bearing_deg())) * (radius + 1.0) + Vector2(-4, 5), "N",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))


## Direction à l'écran d'un angle relatif à l'avant (positif = tribord, à droite).
func _dir(angle: float) -> Vector2:
	return Vector2(sin(angle), -cos(angle))


## Direction d'une voile ou du safran (angle depuis l'axe, vers l'arrière).
func _sail_dir(angle: float) -> Vector2:
	return Vector2(sin(angle), cos(angle))


func _wind_arrow(c: Vector2, radius: float, angle: float, speed: float, color: Color, width: float) -> void:
	if speed < 0.2:
		return
	var outer := c + _dir(angle) * radius
	var inner := c + _dir(angle) * (radius - 14.0 - speed * 3.0)
	draw_line(outer, inner, color, width, true)
	var back := (outer - inner).normalized() * 9.0
	var side := Vector2(-back.y, back.x) * 0.55
	draw_colored_polygon(PackedVector2Array([inner, inner + back + side, inner + back - side]), color)
