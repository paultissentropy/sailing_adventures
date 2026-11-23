extends Node3D
## Bouée de parcours : un cylindre et un chapeau conique, qui dansent sur l'eau.

@export var color := Color(1.0, 0.78, 0.2)

var _phase := randf() * TAU
var _base_y := 0.0


func _ready() -> void:
	_base_y = position.y
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5

	var body := CylinderMesh.new()
	body.top_radius = 0.35
	body.bottom_radius = 0.5
	body.height = 1.4
	body.material = mat
	var body_node := MeshInstance3D.new()
	body_node.mesh = body
	body_node.position.y = 0.4
	add_child(body_node)

	var cap := CylinderMesh.new()
	cap.top_radius = 0.0
	cap.bottom_radius = 0.35
	cap.height = 0.6
	cap.material = mat
	var cap_node := MeshInstance3D.new()
	cap_node.mesh = cap
	cap_node.position.y = 1.4
	add_child(cap_node)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	position.y = _base_y + sin(t * 1.4 + _phase) * 0.06
	rotation.x = sin(t * 1.1 + _phase) * 0.05
	rotation.z = cos(t * 0.9 + _phase) * 0.05
