class_name OrbitCamera
extends Camera3D
## Caméra qui tourne autour du bateau.
## Clic + glisser : tourner. Molette : zoom. C : suivre le cap ou non.
## J / L : regarder par le travers bâbord / tribord (à 90° du cap) ; même touche pour revenir.

@export var target: Boat
@export var distance := 16.0
@export var min_distance := 6.0
@export var max_distance := 60.0
@export var pitch_deg := -16.0
## Si vrai, la caméra se replace doucement derrière le bateau.
@export var follow_heading := true

## Vue de travers : 0 = derrière le bateau, -1 = regarde bâbord, +1 = regarde tribord.
var beam_side := 0

var _yaw_offset := 0.0
var _base_yaw := 0.0
var _beam_angle := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target != null and target.sim != null:
		_base_yaw = target.sim.heading


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_LEFT)):
		_yaw_offset -= event.relative.x * 0.005
		pitch_deg = clampf(pitch_deg - event.relative.y * 0.25, -80.0, -3.0)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(min_distance, distance * 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(max_distance, distance * 1.1)
	elif event.is_action_pressed("camera_toggle"):
		follow_heading = not follow_heading
	elif event.is_action_pressed("look_port"):
		_toggle_beam(-1)
	elif event.is_action_pressed("look_starboard"):
		_toggle_beam(1)


## Relèvement (degrés compas) de la direction regardée.
func view_bearing_deg() -> float:
	var f := -global_basis.z
	return fposmod(rad_to_deg(atan2(f.x, -f.z)), 360.0)


func _toggle_beam(side: int) -> void:
	beam_side = 0 if beam_side == side else side
	_yaw_offset = 0.0


func _process(delta: float) -> void:
	if target == null or target.sim == null:
		return
	if beam_side != 0:
		# Vue de travers : on colle au cap pour lire un relèvement exact.
		_base_yaw = lerp_angle(_base_yaw, target.sim.heading, 1.0 - exp(-6.0 * delta))
	elif follow_heading:
		_base_yaw = lerp_angle(_base_yaw, target.sim.heading, 1.0 - exp(-1.2 * delta))
	# Regarder à bâbord = tourner la vue vers la gauche (angle positif).
	_beam_angle = lerp_angle(_beam_angle, -beam_side * PI * 0.5, 1.0 - exp(-6.0 * delta))
	var focus := target.get_global_transform_interpolated().origin + Vector3(0.0, 2.5, 0.0)
	var orbit := Basis(Vector3.UP, _base_yaw + _beam_angle + _yaw_offset) * Basis(Vector3.RIGHT, deg_to_rad(pitch_deg))
	global_position = focus + orbit * Vector3(0.0, 0.0, distance)
	look_at(focus)
