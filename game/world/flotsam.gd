class_name Flotsam
extends MultiMeshInstance3D
## Repères flottants : taches d'écume, algues et plumes posées sur l'eau, fixes dans le
## monde. Elles défilent le long de la coque et rendent la vitesse visible.
##
## Le monde est découpé en cases ; chaque case tire ses objets d'une graine qui dépend
## de sa position : un objet est toujours au même endroit quand on repasse.

const CELL := 10.0
const RADIUS_CELLS := 5
const PER_CELL := 3
const Y := 0.05

## Sortes d'objets : [couleur, taille mini, taille maxi, allongement].
const KINDS := [
	[Color(1.0, 1.0, 1.0, 0.9), 0.6, 1.5, 1.0],      # tache d'écume
	[Color(0.22, 0.32, 0.12, 1.0), 0.7, 1.4, 0.22],  # algue
	[Color(0.45, 0.3, 0.18, 1.0), 0.35, 0.6, 0.3],   # brindille
	[Color(1.0, 1.0, 0.95, 1.0), 0.25, 0.4, 0.35],   # plume
]

@export var boat: Boat

var _cell := Vector2i(1 << 30, 0)


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = BowWave._soft_dot()
	mat.roughness = 0.9
	plane.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = plane
	var side := RADIUS_CELLS * 2 + 1
	mm.instance_count = side * side * PER_CELL
	multimesh = mm


func _process(_delta: float) -> void:
	if boat == null or boat.sim == null:
		return
	var pos := boat.sim.position
	var cell := Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))
	if cell != _cell:
		_cell = cell
		_rebuild()


func _rebuild() -> void:
	var rng := RandomNumberGenerator.new()
	var index := 0
	for cx in range(_cell.x - RADIUS_CELLS, _cell.x + RADIUS_CELLS + 1):
		for cz in range(_cell.y - RADIUS_CELLS, _cell.y + RADIUS_CELLS + 1):
			rng.seed = hash(Vector2i(cx, cz))
			for i in PER_CELL:
				var kind: Array = KINDS[rng.randi() % KINDS.size()]
				var size := rng.randf_range(kind[1], kind[2])
				var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(size * kind[3], 1.0, size))
				var p := Vector3((cx + rng.randf()) * CELL, Y, (cz + rng.randf()) * CELL)
				multimesh.set_instance_transform(index, Transform3D(basis, p))
				multimesh.set_instance_color(index, kind[0])
				index += 1
