class_name Water
extends MeshInstance3D
## Plan d'eau qui suit la cible (le motif du shader est en coordonnées monde).

@export var target: Node3D


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(_delta: float) -> void:
	if target != null:
		var t := target.global_position
		global_position = Vector3(t.x, 0.0, t.z)


func set_wind(flow: Vector2, speed: float) -> void:
	var mat := mesh.surface_get_material(0) as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("wind_flow", flow.normalized() if flow.length() > 0.01 else Vector2(0.0, 1.0))
	mat.set_shader_parameter("wind_speed", speed)
