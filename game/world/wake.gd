class_name Wake
extends MeshInstance3D
## Trajectoire lisible sur l'eau : un sillage d'écume qui s'efface derrière le bateau,
## et une ligne de cap en pointillés devant l'étrave.

const SAMPLE_PERIOD := 0.1
const WAKE_SECONDS := 25.0
const STERN_OFFSET := 3.0
const HEADING_LINE := [4.0, 70.0]  # début et fin devant l'étrave (m)
const DASH := 2.5
const Y := 0.06

@export var boat: Boat

var _mesh := ImmediateMesh.new()
var _points: Array[Vector3] = []
var _times: PackedFloat32Array = []
var _speeds: PackedFloat32Array = []
var _clock := 0.0
var _timer := 0.0


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.render_priority = 1
	material_override = mat


func clear() -> void:
	_points.clear()
	_times.clear()
	_speeds.clear()


func _process(delta: float) -> void:
	if boat == null or boat.sim == null:
		return
	var sim := boat.sim
	_clock += delta
	_timer += delta
	var origin := boat.get_global_transform_interpolated().origin
	var f := sim.forward()
	var fwd := Vector3(f.x, 0.0, f.y)
	var stern := Vector3(origin.x, Y, origin.z) - fwd * STERN_OFFSET
	if _timer >= SAMPLE_PERIOD:
		_timer = 0.0
		_points.append(stern)
		_times.append(_clock)
		_speeds.append(sim.speed())
		while _times.size() > 0 and _clock - _times[0] > WAKE_SECONDS:
			_points.pop_front()
			_times.remove_at(0)
			_speeds.remove_at(0)

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(stern, stern, stern, stern, Color.TRANSPARENT, Color.TRANSPARENT)  # surface jamais vide

	# Sillage : bande qui s'élargit et s'efface avec l'âge, plus marquée quand on va vite.
	var pts := _points.duplicate()
	pts.append(stern)
	var n := pts.size()
	for i in range(1, n):
		var a: Vector3 = pts[i - 1]
		var b: Vector3 = pts[i]
		var seg := b - a
		if seg.length_squared() < 1e-6:
			continue
		var side := Vector3(-seg.z, 0.0, seg.x).normalized()
		var ca := _wake_color(i - 1)
		var cb := _wake_color(i)  # le dernier point est la poupe actuelle
		_quad(a - side * _width(i - 1), a + side * _width(i - 1),
			b - side * _width(i), b + side * _width(i), ca, cb)

	# Ligne de cap : pointillés devant l'étrave.
	var bow := Vector3(origin.x, Y, origin.z)
	var right := Vector3(-fwd.z, 0.0, fwd.x) * 0.08
	var d: float = HEADING_LINE[0]
	while d < HEADING_LINE[1]:
		var t := 1.0 - (d - HEADING_LINE[0]) / (HEADING_LINE[1] - HEADING_LINE[0])
		var col := Color(1, 1, 1, 0.45 * t)
		var p0 := bow + fwd * d
		var p1 := bow + fwd * (d + DASH)
		_quad(p0 - right, p0 + right, p1 - right, p1 + right, col, col)
		d += DASH * 2.0
	_mesh.surface_end()


func _age_ratio(i: int) -> float:
	if i < 0 or i >= _times.size():
		return 0.0
	return clampf((_clock - _times[i]) / WAKE_SECONDS, 0.0, 1.0)


func _wake_color(i: int) -> Color:
	var speed: float = boat.sim.speed() if i < 0 or i >= _speeds.size() else _speeds[i]
	var strength := clampf(speed / 2.0, 0.0, 1.0)
	var fade := 1.0 - _age_ratio(i)
	return Color(0.9, 0.96, 1.0, 0.28 * strength * fade * fade)


func _width(i: int) -> float:
	return 0.35 + 1.6 * _age_ratio(i)


func _quad(a0: Vector3, a1: Vector3, b0: Vector3, b1: Vector3, ca: Color, cb: Color) -> void:
	for v in [[a0, ca], [b0, cb], [b1, cb], [a0, ca], [b1, cb], [a1, ca]]:
		_mesh.surface_set_color(v[1])
		_mesh.surface_add_vertex(v[0])
