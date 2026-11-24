class_name Boat
extends Node3D
## Le bateau : lit les commandes, fait avancer la simulation (`BoatSim`) et met à jour
## le visuel. Repère local : origine à la flottaison au centre de dérive, avant vers -Z.
## Le modèle 3D est dessiné pour un bateau de 6 m ; le nœud est mis à l'échelle
## (`BoatParams.visual_scale`) et les longueurs de la simulation sont ramenées en unités
## du modèle par `_m()`.

## Unités du modèle (bateau de 6 m) :
## Course d'écoute par seconde (0..1).
const SHEET_RATE := 0.3
const RUDDER_RATE := 1.6
const RUDDER_RETURN := 1.0

const DECK_Y := 0.6
const BOOM_Y := 1.6
const MAST_TOP_Y := 7.6
const JIB_HEAD_Y := 6.3

@export var params: BoatParams
## Cap compas au départ (degrés).
@export var start_bearing_deg := 90.0

var sim: BoatSim
var wind: WindField

var _time := 0.0
var _k := 1.0
var _rigging_mesh := ImmediateMesh.new()
var _main_ease := SheetInput.new()
var _jib_ease := SheetInput.new()

@onready var _mast: Node3D = $Mast
@onready var _boom_pivot: Node3D = $BoomPivot
@onready var _rudder_pivot: Node3D = $RudderPivot
@onready var _windex: Node3D = $Windex
@onready var _main_sail: SailMesh = $MainSail
@onready var _jib: SailMesh = $Jib
@onready var _rigging: MeshInstance3D = $Rigging


func _ready() -> void:
	_rigging.mesh = _rigging_mesh
	var rope := StandardMaterial3D.new()
	rope.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rope.albedo_color = Color(0.25, 0.22, 0.2)
	_rigging.material_override = rope
	set_params(params)


## Change de bateau (préréglage `BoatParams`) et replace le bateau au départ.
func set_params(new_params: BoatParams) -> void:
	params = new_params
	sim = BoatSim.new(params.duplicate() if params != null else null)
	var p := sim.p
	_k = p.visual_scale
	scale = Vector3.ONE * _k
	_mast.position.z = -_m(p.mast_x)
	_boom_pivot.position = Vector3(0.0, BOOM_Y, -_m(p.mast_x))
	_rudder_pivot.position.z = -_m(p.rudder_x)
	_windex.position = Vector3(0.0, MAST_TOP_Y + 0.1, -_m(p.mast_x))
	reset()


## Échelle du modèle 3D (1 pour 6 m).
func model_scale() -> float:
	return _k


## Longueur de la simulation (m) en unités du modèle.
func _m(meters: float) -> float:
	return meters / _k


func reset() -> void:
	sim.reset(Vector2.ZERO, deg_to_rad(-start_bearing_deg))
	sim.main_sheet = 0.5
	sim.jib_sheet = 0.5
	sim.rudder = 0.0
	# Foc sous le vent : du côté vers lequel souffle le vent.
	if wind != null:
		var side := signf(wind.sample(sim.position).dot(sim.right()))
		sim.jib_side = side if side != 0.0 else 1.0
	sim.main_angle = deg_to_rad(30.0) * sim.jib_side
	sim.jib_angle = deg_to_rad(30.0) * sim.jib_side
	_apply_transform()
	reset_physics_interpolation()


func _physics_process(dt: float) -> void:
	if wind == null:
		return
	_time += dt
	_read_controls(dt)
	sim.step(dt, wind.sample(sim.position))
	_apply_transform()


func _process(_delta: float) -> void:
	_update_sails()


func _read_controls(dt: float) -> void:
	var steer := Input.get_axis("helm_left", "helm_right")
	if steer != 0.0:
		sim.rudder = move_toward(sim.rudder, steer, RUDDER_RATE * dt)
	else:
		sim.rudder = move_toward(sim.rudder, 0.0, RUDDER_RETURN * dt)
	sim.main_sheet = clampf(sim.main_sheet + Input.get_axis("main_in", "main_out") * SHEET_RATE * dt, 0.0, 1.0)
	sim.jib_sheet = clampf(sim.jib_sheet + Input.get_axis("jib_in", "jib_out") * SHEET_RATE * dt, 0.0, 1.0)
	# Double appui rapide sur « choquer » : l'écoute file en grand.
	if Input.is_action_just_pressed("main_out") and _main_ease.press(_time):
		sim.main_sheet = 1.0
	if Input.is_action_just_pressed("jib_out") and _jib_ease.press(_time):
		sim.jib_sheet = 1.0


func _apply_transform() -> void:
	var bob := sin(_time * 1.3) * 0.03 * _k
	position = Vector3(sim.position.x, bob, sim.position.y)
	var pitch := 0.01 * sin(_time * 0.9) + 0.006 * sim.u
	rotation = Vector3(pitch, sim.heading, -sim.heel)
	_boom_pivot.rotation.y = sim.main_angle
	_rudder_pivot.rotation.y = sim.rudder_angle()
	# La girouette pointe d'où vient le vent apparent.
	var from := -sim.apparent_wind
	_windex.rotation.y = atan2(-from.y, from.x)


## Vecteur du repère bateau 2D (avant, tribord) vers le repère local 3D.
static func body_to_local(v: Vector2) -> Vector3:
	return Vector3(v.y, 0.0, -v.x)


func _update_sails() -> void:
	var p := sim.p
	var aws := sim.apparent_wind.length()
	var flutter_amp := clampf(aws / 6.0, 0.2, 1.5)
	# Dans le lit du vent (virement), les voiles battent franchement.
	var flog := 1.0 - smoothstep(deg_to_rad(4.0), deg_to_rad(20.0), absf(sim.free_angle))

	var main_tack := Vector3(0.0, BOOM_Y + 0.05, -_m(p.mast_x))
	var main_head := Vector3(0.0, MAST_TOP_Y - 0.1, -_m(p.mast_x))
	var main_clew := main_tack + Vector3(sin(sim.main_angle), 0.0, cos(sim.main_angle)) * (_m(p.boom_length) - 0.05)
	var main_fill := smoothstep(deg_to_rad(2.0), deg_to_rad(12.0), sim.main_alpha)
	_main_sail.update_sail(main_tack, main_head, main_clew, _belly("main"), main_fill,
		maxf(1.0 - main_fill, flog) * flutter_amp * (1.0 + flog), _time)

	var jib_tack := Vector3(0.0, DECK_Y + 0.15, -_m(p.jib_tack_x))
	var jib_head := Vector3(0.0, JIB_HEAD_Y, -_m(p.mast_x) - 0.25)
	var jib_clew := jib_tack + Vector3(sin(sim.jib_angle), 0.25, cos(sim.jib_angle)) * _m(p.jib_foot)
	var jib_fill := smoothstep(deg_to_rad(2.0), deg_to_rad(12.0), sim.jib_alpha)
	_jib.update_sail(jib_tack, jib_head, jib_clew, _belly("jib"), jib_fill,
		maxf(1.0 - jib_fill, flog) * flutter_amp * (1.0 + 1.5 * flog), _time)

	_update_rigging(main_clew, jib_tack, jib_clew)


func _belly(sail: String) -> Vector3:
	if not sim.forces.has(sail):
		return Vector3.RIGHT
	return body_to_local(sim.forces[sail][1])


func _update_rigging(main_clew: Vector3, jib_tack: Vector3, jib_clew: Vector3) -> void:
	var p := sim.p
	var mast_top := Vector3(0.0, MAST_TOP_Y, -_m(p.mast_x))
	var stern := Vector3(0.0, DECK_Y, -_m(p.rudder_x) - 0.1)
	_rigging_mesh.clear_surfaces()
	_rigging_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# Étai, pataras, haubans
	_line(jib_tack + Vector3(0.0, -0.1, -0.1), mast_top + Vector3(0.0, -1.2, 0.0))
	_line(mast_top, stern)
	for side in [-1.0, 1.0]:
		_line(mast_top + Vector3(0.0, -1.0, 0.0), Vector3(side * 0.95, DECK_Y, -_m(p.mast_x) + 0.3))
	# Écoute de GV (du bout de bôme au cockpit) et écoute de foc en service
	_line(main_clew, Vector3(0.0, DECK_Y + 0.05, main_clew.z))
	_line(jib_clew, Vector3(sim.jib_side * 0.9, DECK_Y + 0.05, -_m(p.mast_x) + 0.6))
	_rigging_mesh.surface_end()


func _line(a: Vector3, b: Vector3) -> void:
	_rigging_mesh.surface_add_vertex(a)
	_rigging_mesh.surface_add_vertex(b)
