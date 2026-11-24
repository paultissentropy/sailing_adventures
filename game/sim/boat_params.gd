class_name BoatParams
extends Resource
## Paramètres physiques d'un petit quillard de ~6 m (unités SI).
##
## Les positions `*_x` sont mesurées vers l'avant depuis le centre de dérive (la quille).
## Vérifier la polaire (`tools/polar.sh`) après chaque modification.

@export_group("Masse et inertie")
@export var mass := 1100.0
## Masse ajoutée (fraction de la masse) en avançant / en glissant sur le côté.
@export var added_mass_surge := 0.05
@export var added_mass_sway := 0.5
@export var yaw_inertia := 2800.0
@export var roll_inertia := 1800.0
## Hauteur métacentrique (m) : stabilité de forme et de poids.
@export var metacentric_height := 1.0
@export var roll_damping := 6000.0

@export_group("Coque")
## Vitesse de carène (m/s) : la résistance explose au-delà.
@export var hull_speed := 2.9
@export var hull_drag := 21.0
@export var wave_drag := 3.0
@export var hull_side_linear := 300.0
@export var hull_side_quad := 900.0
@export var yaw_damping_linear := 400.0
@export var yaw_damping_speed := 600.0
@export var yaw_damping_quad := 2000.0
## Couple ardent dû à la carène gîtée (N·m par radian de gîte et par (m/s)²).
@export var heel_helm := 200.0
## Surface de fardage (coque et gréement), en m².
@export var windage_area := 2.0

@export_group("Quille")
@export var keel_x := 0.0
@export var keel_area := 0.75
@export var keel_cl_max := 1.0
@export var keel_stall_deg := 22.0
@export var keel_cd0 := 0.01
@export var keel_k_induced := 0.08

@export_group("Safran")
@export var rudder_x := -2.8
@export var rudder_area := 0.2
@export var rudder_max_deg := 35.0
@export var rudder_cl_max := 1.1
@export var rudder_stall_deg := 20.0
@export var rudder_cd0 := 0.012
@export var rudder_k_induced := 0.08

@export_group("Gréement")
@export var mast_x := 0.0
@export var boom_length := 2.8
@export var main_area := 11.0
## Angle de bôme écoute bordée à fond / choquée à fond.
@export var main_min_deg := 2.0
@export var main_max_deg := 85.0
@export var jib_tack_x := 2.4
@export var jib_foot := 2.2
@export var jib_area := 6.5
@export var jib_min_deg := 10.0
@export var jib_max_deg := 75.0
## Hauteur du centre de voilure au-dessus de la flottaison (m).
@export var ce_height := 3.0
@export var sail_cl_max := 1.5
@export var sail_stall_deg := 22.0
@export var sail_cd0 := 0.08
@export var sail_k_induced := 0.1
## Traînée supplémentaire d'une voile qui faseye (elle bat au vent).
@export var sail_flutter_cd := 0.25
## Le vent doit passer de ce nombre de degrés « sous la bôme » avant qu'elle bascule.
@export var by_the_lee_deg := 12.0
## Si vrai, le foc passe tout seul sous le vent : il n'est jamais à contre.
@export var auto_jib := true

@export_group("Simplifications (jouabilité)")
## Les voiles voient le vent apparent (sinon : vent réel seul).
@export var use_apparent_wind := false
## Les voiles, la gîte et la carène font tourner le bateau (sinon : seule la barre).
@export var sail_yaw_effects := false
## Le bateau peut glisser sur le côté (dérive).
@export var allow_leeway := false
## Vent réel seul : la portance des voiles s'éteint sous `pointing_min_deg` du vent et
## n'est pleine qu'au-delà de `pointing_full_deg`. Remplace l'effet du vent apparent
## qui, en vrai, empêche de remonter trop près du vent.
@export var pointing_min_deg := 30.0
@export var pointing_full_deg := 48.0
## Barre seule : vitesse de rotation à fond de barre (°/s) et vitesse à partir de
## laquelle la barre a tout son effet (m/s).
@export var turn_rate_max_deg := 20.0
@export var turn_full_speed := 1.5
## Barre seule : réactivité de la rotation (1/s).
@export var turn_response := 4.0
