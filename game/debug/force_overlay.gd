class_name ForceOverlay
extends MeshInstance3D
## Affichage de debug (F1) : vecteurs de vent et de forces, et trace du bateau.
##
## Bleu : vent réel. Cyan : vent apparent. Blanc : vitesse du bateau.
## Rouge : grand-voile. Orange : foc. Vert : quille. Jaune : safran. Gris : coque et fardage.

const FORCE_SCALE := 1.0 / 150.0   # m par newton
const WIND_SCALE := 0.6            # m par m/s
const TRAIL_PERIOD := 0.25
const TRAIL_POINTS := 600

const COLORS := {
	"main": Color(1.0, 0.25, 0.2),
	"jib": Color(1.0, 0.6, 0.1),
	"keel": Color(0.2, 0.9, 0.3),
	"rudder": Color(1.0, 0.95, 0.2),
	"hull": Color(0.6, 0.6, 0.6),
	"windage": Color(0.75, 0.75, 0.75),
}
const HEIGHTS := {"main": 3.0, "jib": 2.5, "keel": -0.6, "rudder": -0.3, "hull": 0.2, "windage": 1.5}

@export var boat: Boat

var _mesh := ImmediateMesh.new()
var _trail := PackedVector3Array()
var _trail_timer := 0.0


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true
	mat.render_priority = 10
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func clear_trail() -> void:
	_trail.clear()


func _process(delta: float) -> void:
	if boat == null or boat.sim == null:
		return
	var sim := boat.sim
	var origin := boat.get_global_transform_interpolated().origin
	origin.y = 0.0
	_trail_timer += delta
	if _trail_timer >= TRAIL_PERIOD:
		_trail_timer = 0.0
		_trail.append(origin + Vector3(0.0, 0.05, 0.0))
		if _trail.size() > TRAIL_POINTS:
			_trail.remove_at(0)
	if not visible:
		return

	var f := sim.forward()
	var r := sim.right()
	var f3 := Vector3(f.x, 0.0, f.y)
	var r3 := Vector3(r.x, 0.0, r.y)

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_seg(origin, origin, Color.TRANSPARENT)  # une surface ne peut pas être vide
	for key: String in sim.forces:
		var pt: Vector2 = sim.forces[key][0]
		var fo: Vector2 = sim.forces[key][1]
		var start: Vector3 = origin + f3 * pt.x + r3 * pt.y + Vector3.UP * HEIGHTS.get(key, 1.0)
		_arrow(start, (f3 * fo.x + r3 * fo.y) * FORCE_SCALE, COLORS.get(key, Color.WHITE))
	var top := origin + Vector3.UP * 8.5
	var tw := sim.true_wind
	_arrow(top - Vector3(tw.x, 0.0, tw.y) * WIND_SCALE, Vector3(tw.x, 0.0, tw.y) * WIND_SCALE, Color(0.3, 0.5, 1.0))
	var aw := f3 * sim.apparent_wind.x + r3 * sim.apparent_wind.y
	_arrow(top + Vector3.UP * 0.3 - aw * WIND_SCALE, aw * WIND_SCALE, Color(0.3, 0.95, 1.0))
	var vel := sim.velocity()
	_arrow(origin + Vector3.UP * 0.8, Vector3(vel.x, 0.0, vel.y), Color.WHITE)
	for i in range(1, _trail.size()):
		_mesh.surface_set_color(Color(1.0, 1.0, 1.0, 0.6))
		_mesh.surface_add_vertex(_trail[i - 1])
		_mesh.surface_set_color(Color(1.0, 1.0, 1.0, 0.6))
		_mesh.surface_add_vertex(_trail[i])
	_mesh.surface_end()


func _arrow(start: Vector3, vec: Vector3, color: Color) -> void:
	if vec.length() < 0.05:
		return
	var end := start + vec
	_seg(start, end, color)
	var back := -vec.normalized() * minf(0.4, vec.length() * 0.3)
	var side := back.cross(Vector3.UP).normalized() * back.length() * 0.5
	if side.length_squared() < 1e-6:
		side = Vector3.RIGHT * back.length() * 0.5
	_seg(end, end + back + side, color)
	_seg(end, end + back - side, color)


func _seg(a: Vector3, b: Vector3, color: Color) -> void:
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(a)
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(b)
