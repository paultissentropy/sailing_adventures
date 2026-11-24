extends Node3D
## Bac à sable P0 : eau plate, bouées, vent réglable.

const WIND_STEP_DEG := 15.0
const WIND_STEP_KN := 2.0

@export var wind: WindField

@onready var _boat: Boat = $Boat
@onready var _water: Water = $Water
@onready var _hud: Hud = $HUD
@onready var _overlay: ForceOverlay = $ForceOverlay
@onready var _camera: OrbitCamera = $Camera
@onready var _wake: Wake = $Wake


func _ready() -> void:
	if wind == null:
		wind = WindField.new()
	_boat.wind = wind
	_boat.reset()
	var buoys: Array[Node3D] = []
	for buoy in $Buoys.get_children():
		buoys.append(buoy)
	_hud.setup(_boat, wind, _camera, buoys)
	_overlay.visible = "--debug" in OS.get_cmdline_user_args()


func _physics_process(dt: float) -> void:
	wind.advance(dt)


func _process(_delta: float) -> void:
	var w := wind.sample(_boat.sim.position)
	_water.set_wind(w, w.length())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("wind_left"):
		wind.from_deg = fposmod(wind.from_deg - WIND_STEP_DEG, 360.0)
	elif event.is_action_pressed("wind_right"):
		wind.from_deg = fposmod(wind.from_deg + WIND_STEP_DEG, 360.0)
	elif event.is_action_pressed("wind_down"):
		wind.speed_knots = maxf(0.0, wind.speed_knots - WIND_STEP_KN)
	elif event.is_action_pressed("wind_up"):
		wind.speed_knots = minf(30.0, wind.speed_knots + WIND_STEP_KN)
	elif event.is_action_pressed("reset_boat"):
		_boat.reset()
		_overlay.clear_trail()
		_wake.clear()
	elif event.is_action_pressed("instruments_toggle"):
		_hud.toggle_instruments()
	elif event.is_action_pressed("debug_toggle"):
		_overlay.visible = not _overlay.visible
	elif event.is_action_pressed("help_toggle"):
		_hud.toggle_help()
