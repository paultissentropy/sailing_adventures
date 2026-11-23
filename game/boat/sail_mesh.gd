class_name SailMesh
extends MeshInstance3D
## Voile triangulaire procédurale : elle se creuse quand elle porte et bat quand
## elle faseye. Recalculée à chaque image à partir de trois points (repère du bateau).

const ROWS := 8
const COLS := 6

@export var color := Color(0.99, 0.97, 0.9)
## Creux maximal, relatif à la corde.
@export var depth := 0.12

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	material_override = mat


## `belly` : direction du creux (sous le vent). `fill` : 0 (faseye) à 1 (pleine).
## `flutter` : amplitude du battement.
func update_sail(tack: Vector3, head: Vector3, clew: Vector3, belly: Vector3, fill: float,
		flutter: float, time: float) -> void:
	var luff_axis := (head - tack).normalized()
	var grid: Array[PackedVector3Array] = []
	for i in ROWS + 1:
		var s := float(i) / ROWS
		var a := tack.lerp(head, s)
		var b := clew.lerp(head, s)
		var chord := b - a
		var n := chord.cross(luff_axis).normalized()
		if n.dot(belly) < 0.0:
			n = -n
		var row := PackedVector3Array()
		for j in COLS + 1:
			var c := float(j) / COLS
			var shape := sin(PI * c) * (1.0 - 0.35 * c)  # creux plus marqué vers l'avant
			var offset := shape * depth * chord.length() * fill
			offset += flutter * 0.1 * sin(PI * c) * sin(time * 17.0 + c * 7.0 + s * 3.0)
			row.append(a.lerp(b, c) + n * offset)
		grid.append(row)

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in ROWS:
		for j in COLS:
			_tri(grid[i][j], grid[i + 1][j], grid[i + 1][j + 1])
			_tri(grid[i][j], grid[i + 1][j + 1], grid[i][j + 1])
	_mesh.surface_end()


func _tri(a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-10:
		return
	n = n.normalized()
	for p in [a, b, c]:
		_mesh.surface_set_normal(n)
		_mesh.surface_add_vertex(p)
