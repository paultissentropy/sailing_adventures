@tool
extends MeshInstance3D
## Coque procédurale arrondie, style jouet. L'origine est à la flottaison, au centre
## de dérive ; l'avant est vers -Z.

@export var length := 6.0
@export var beam := 2.2
@export var freeboard := 0.55
@export var draft := 0.4
@export var hull_color := Color(0.97, 0.95, 0.9)
@export var stripe_color := Color(0.9, 0.36, 0.3)
@export var deck_color := Color(0.85, 0.7, 0.5)

const STATIONS := 28
const SECTION := 10


func _ready() -> void:
	mesh = build()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.75
	material_override = mat


func build() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections: Array = []
	for i in STATIONS + 1:
		sections.append(_section(float(i) / STATIONS))

	# Bordé : faces orientées dans le sens horaire vues de l'extérieur.
	for i in STATIONS:
		var a: PackedVector3Array = sections[i]
		var b: PackedVector3Array = sections[i + 1]
		for j in SECTION:
			# Tribord (x > 0)
			_tri(st, b[j], a[j], a[j + 1])
			_tri(st, b[j], a[j + 1], b[j + 1])
			# Bâbord (miroir)
			_tri(st, _mirror(a[j]), _mirror(b[j]), _mirror(a[j + 1]))
			_tri(st, _mirror(a[j + 1]), _mirror(b[j]), _mirror(b[j + 1]))

	# Pont légèrement bombé
	for i in STATIONS:
		var a: PackedVector3Array = sections[i]
		var b: PackedVector3Array = sections[i + 1]
		var ca := Vector3(0.0, a[0].y + 0.05, a[0].z)
		var cb := Vector3(0.0, b[0].y + 0.05, b[0].z)
		_tri(st, _mirror(a[0]), ca, cb, deck_color)
		_tri(st, _mirror(a[0]), cb, _mirror(b[0]), deck_color)
		_tri(st, ca, a[0], b[0], deck_color)
		_tri(st, ca, b[0], cb, deck_color)

	# Tableau arrière
	var stern: PackedVector3Array = sections[STATIONS]
	var center := Vector3(0.0, (stern[0].y + stern[SECTION].y) * 0.5, stern[0].z)
	var ring := PackedVector3Array()
	for j in SECTION + 1:
		ring.append(stern[j])
	for j in range(SECTION, -1, -1):
		ring.append(_mirror(stern[j]))
	for k in ring.size():
		_tri(st, center, ring[k], ring[(k + 1) % ring.size()], hull_color)

	st.generate_normals()
	return st.commit()


## Points d'une section, du livet tribord (pont) jusqu'à la quille.
func _section(t: float) -> PackedVector3Array:
	var z := -length * 0.5 + t * length
	var half := _half_beam(t)
	var deck_y := freeboard + 0.18 * pow(1.0 - t, 2.0)
	var bottom_y := -draft * (0.35 + 0.65 * sin(PI * clampf(t * 0.9 + 0.05, 0.0, 1.0)))
	var pts := PackedVector3Array()
	for j in SECTION + 1:
		var phi := 0.5 * PI * float(j) / SECTION
		var x := half * pow(cos(phi), 0.6)
		var y := deck_y - (deck_y - bottom_y) * sin(phi)
		pts.append(Vector3(x, y, z))
	return pts


func _half_beam(t: float) -> float:
	if t < 0.55:
		return beam * 0.5 * pow(sin(0.5 * PI * t / 0.55), 0.65)
	var k := (t - 0.55) / 0.45
	return beam * 0.5 * (1.0 - 0.22 * k * k)


func _mirror(p: Vector3) -> Vector3:
	return Vector3(-p.x, p.y, p.z)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color = Color.TRANSPARENT) -> void:
	for p in [a, b, c]:
		st.set_color(color if color.a > 0.0 else _side_color(p))
		st.add_vertex(p)


func _side_color(p: Vector3) -> Color:
	return stripe_color if p.y > freeboard - 0.14 else hull_color
