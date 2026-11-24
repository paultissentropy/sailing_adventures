class_name BowWave
extends MeshInstance3D
## Moustache d'étrave : deux rubans d'écume en V qui partent de l'étrave et s'ouvrent
## avec la vitesse, plus des gerbes d'écume dont le débit suit la vitesse.

const HALF_ANGLE := deg_to_rad(24.0)
const SEGMENTS := 10
const Y := 0.07

@export var boat: Boat

var _mesh := ImmediateMesh.new()
var _spray: GPUParticles3D


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
	mat.render_priority = 2
	material_override = mat
	_spray = _make_spray()
	add_child(_spray)


func _process(_delta: float) -> void:
	if boat == null or boat.sim == null:
		return
	var sim := boat.sim
	var k := boat.model_scale()
	var ratio := clampf(sim.u / sim.p.hull_speed, 0.0, 1.3)
	var origin := boat.get_global_transform_interpolated().origin
	var f := sim.forward()
	var fwd := Vector3(f.x, 0.0, f.y)
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var bow := Vector3(origin.x, Y, origin.z) + fwd * (2.9 * k)

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_tri(bow, bow, bow, Color.TRANSPARENT)  # surface jamais vide
	if ratio > 0.05:
		var length := sim.p.length * (0.25 + 0.6 * ratio)
		var alpha := 0.5 * smoothstep(0.05, 0.6, ratio)
		for side: float in [-1.0, 1.0]:
			# La moustache longe la coque puis s'en écarte.
			var dir := (-fwd * cos(HALF_ANGLE) + right * side * sin(HALF_ANGLE)).normalized()
			var prev := bow + right * side * 0.15 * k
			for i in range(1, SEGMENTS + 1):
				var s := float(i) / SEGMENTS
				var p := bow + dir * length * s + right * side * 0.15 * k
				var w0 := (0.1 + 0.45 * ratio * (s - 1.0 / SEGMENTS)) * k
				var w1 := (0.1 + 0.45 * ratio * s) * k
				var f0 := 1.0 - (s - 1.0 / SEGMENTS)
				var c0 := Color(0.95, 0.98, 1.0, alpha * f0 * f0)
				var c1 := Color(0.95, 0.98, 1.0, alpha * (1.0 - s) * (1.0 - s))
				var n := Vector3(-dir.z, 0.0, dir.x)
				_quad(prev - n * w0, prev + n * w0, p - n * w1, p + n * w1, c0, c1)
				prev = p
	_mesh.surface_end()

	_spray.global_position = bow + Vector3.UP * 0.2 * k
	_spray.amount_ratio = clampf((ratio - 0.35) / 0.65, 0.0, 1.0)
	_spray.emitting = _spray.amount_ratio > 0.0
	var pm := _spray.process_material as ParticleProcessMaterial
	pm.direction = Vector3(fwd.x * 0.6, 1.0, fwd.z * 0.6)


func _make_spray() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 60
	p.lifetime = 0.9
	p.local_coords = false
	p.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.3
	pm.spread = 55.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.6
	pm.gravity = Vector3(0.0, -9.8, 0.0)
	pm.scale_min = 0.08
	pm.scale_max = 0.22
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.9))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _soft_dot()
	quad.material = mat
	p.draw_pass_1 = quad
	return p


## Petite tache ronde et floue, pour les gouttes et l'écume.
static func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 32
	tex.height = 32
	return tex


func _quad(a0: Vector3, a1: Vector3, b0: Vector3, b1: Vector3, ca: Color, cb: Color) -> void:
	for v in [[a0, ca], [b0, cb], [b1, cb], [a0, ca], [b1, cb], [a1, ca]]:
		_mesh.surface_set_color(v[1])
		_mesh.surface_add_vertex(v[0])


func _tri(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	for v in [a, b, c]:
		_mesh.surface_set_color(color)
		_mesh.surface_add_vertex(v)
