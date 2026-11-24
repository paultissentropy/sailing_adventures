class_name WindStreaks
extends MeshInstance3D
## Lignes de vent : traits blancs translucides qui filent dans le sens du vent autour
## du bateau. Ils montrent d'où vient le vent sans aucun chiffre.

const COUNT := 40
const RADIUS := 45.0
const WIDTH := 0.07

@export var boat: Boat
@export var camera: Camera3D

var _mesh := ImmediateMesh.new()
var _pos: PackedVector3Array = []
var _age: PackedFloat32Array = []
var _life: PackedFloat32Array = []
var _started := false


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
	material_override = mat
	_pos.resize(COUNT)
	_age.resize(COUNT)
	_life.resize(COUNT)
	for i in COUNT:
		_life[i] = 1.0
		_age[i] = 1.0  # apparition au premier passage


func _process(delta: float) -> void:
	if boat == null or boat.sim == null or boat.wind == null:
		return
	var center := boat.get_global_transform_interpolated().origin
	var tw := boat.sim.true_wind
	var speed := tw.length()
	var flow := Vector3(tw.x, 0.0, tw.y)
	var dir := flow.normalized() if speed > 0.1 else Vector3.FORWARD
	var length := clampf(speed * 0.5, 0.8, 5.0)
	var eye := camera.global_position if camera != null else center + Vector3.UP * 10.0

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(center, center, Vector3.ZERO, Color.TRANSPARENT)  # une surface ne peut pas être vide
	for i in COUNT:
		_age[i] += delta / _life[i]
		var p := _pos[i] + flow * delta
		var off := Vector2(p.x - center.x, p.z - center.z)
		if _age[i] >= 1.0 or off.length() > RADIUS * 1.2:
			p = _spawn(center, dir)
			_age[i] = 0.0 if _started else randf()  # départs décalés
			_life[i] = randf_range(2.5, 4.5)
		_pos[i] = p
		if speed < 0.3:
			continue
		var alpha := sin(PI * _age[i]) * 0.55
		var side := dir.cross(eye - p).normalized() * WIDTH
		_quad(p - dir * length, p, side, Color(1, 1, 1, alpha))
	_mesh.surface_end()
	_started = true


## Nouveau trait, plutôt au vent du bateau pour qu'il traverse la scène.
func _spawn(center: Vector3, dir: Vector3) -> Vector3:
	var a := randf() * TAU
	var r := sqrt(randf()) * RADIUS
	var p := center + Vector3(cos(a) * r, 0.0, sin(a) * r) - dir * RADIUS * 0.3
	p.y = randf_range(0.4, 3.5)
	return p


func _quad(tail: Vector3, head: Vector3, side: Vector3, color: Color) -> void:
	var tail_color := Color(color, 0.0)
	for v in [[tail - side, tail_color], [head - side, color], [head + side, color],
			[tail - side, tail_color], [head + side, color], [tail + side, tail_color]]:
		_mesh.surface_set_color(v[1])
		_mesh.surface_add_vertex(v[0])
