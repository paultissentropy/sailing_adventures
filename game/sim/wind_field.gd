class_name WindField
extends Resource
## Champ de vent : `sample(position)` donne la vitesse de l'air (m/s, monde 2D) à
## l'instant courant (`time`, avancé par `advance()`).
##
## Couches :
## 1. vent de base (météo) : direction et force réglables ;
## 2. risées (optionnelles) : bruit qui se déplace avec le vent, qui fait varier la force
##    et la direction ;
## 3. relief : à venir (P1).

const KNOT := 0.514444

## D'où vient le vent, en degrés (0 = nord = -Z, 90 = est = +X).
@export_range(0.0, 360.0) var from_deg := 0.0
@export_range(0.0, 40.0) var speed_knots := 10.0
@export var gusts_enabled := false
## Variation relative de la force dans les risées.
@export_range(0.0, 1.0) var gust_strength := 0.3
## Amplitude des bascules de direction (degrés).
@export_range(0.0, 45.0) var gust_shift_deg := 10.0
## Taille typique d'une risée (m).
@export var gust_size := 120.0

var time := 0.0

var _noise_speed: FastNoiseLite
var _noise_dir: FastNoiseLite


func advance(dt: float) -> void:
	time += dt


func sample(pos: Vector2) -> Vector2:
	var dir := deg_to_rad(from_deg)
	var spd := speed_knots * KNOT
	if gusts_enabled and spd > 0.0:
		_ensure_noise()
		# Les risées se déplacent à peu près à la vitesse du vent.
		var drift := pos - flow_direction(dir) * spd * time * 0.8
		spd *= maxf(0.0, 1.0 + gust_strength * _noise_speed.get_noise_3d(drift.x, drift.y, time * 0.5))
		dir += deg_to_rad(gust_shift_deg) * _noise_dir.get_noise_3d(drift.x, drift.y, time * 0.3)
	return flow_direction(dir) * spd


## Direction (unitaire) vers laquelle va l'air quand le vent vient de `from_rad`.
static func flow_direction(from_rad: float) -> Vector2:
	return Vector2(-sin(from_rad), cos(from_rad))


func _ensure_noise() -> void:
	if _noise_speed != null:
		return
	_noise_speed = FastNoiseLite.new()
	_noise_speed.seed = 1
	_noise_speed.frequency = 1.0 / gust_size
	_noise_speed.fractal_octaves = 2
	_noise_dir = FastNoiseLite.new()
	_noise_dir.seed = 2
	_noise_dir.frequency = 0.5 / gust_size
	_noise_dir.fractal_octaves = 1
