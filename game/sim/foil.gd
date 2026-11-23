class_name Foil
extends RefCounted
## Coefficients simplifiés d'un profil : voile (dans l'air), quille ou safran (dans l'eau).
##
## Jusqu'au décrochage, la portance suit une courbe douce jusqu'à `cl_max`. Au-delà,
## elle rejoint progressivement celle d'une plaque plane. La traînée combine une
## traînée de base, une traînée induite (∝ CL²) et une traînée de forme (∝ sin² α).


## Retourne `Vector2(CL, CD)` pour une incidence `alpha` en radians (0..PI).
## `symmetric` : profil symétrique (quille, safran) qui porte aussi bien à l'envers.
static func coefficients(alpha: float, cl_max: float, alpha_stall: float, cd0: float,
		k_induced: float, symmetric: bool = false) -> Vector2:
	alpha = clampf(alpha, 0.0, PI)
	if symmetric and alpha > PI * 0.5:
		# Écoulement venant du bord de fuite : même profil, portance inversée.
		var c := coefficients(PI - alpha, cl_max, alpha_stall, cd0, k_induced, false)
		return Vector2(-c.x, c.y)

	var cl_flat := 1.1 * sin(2.0 * alpha)
	var cl: float
	if alpha < alpha_stall:
		cl = cl_max * sin(0.5 * PI * alpha / alpha_stall)
	elif alpha < PI * 0.5:
		var w := exp(-(alpha - alpha_stall) / deg_to_rad(8.0))
		cl = lerpf(cl_flat, cl_max, w)
	else:
		cl = cl_flat

	var s := sin(alpha)
	var cd := cd0 + k_induced * cl * cl + 1.2 * s * s
	return Vector2(cl, cd)


## Direction unitaire de la portance pour un écoulement `flow` (unitaire) sur une
## corde `chord` (unitaire, du bord d'attaque vers le bord de fuite).
## Elle est perpendiculaire à l'écoulement, du côté opposé à la déviation de l'air.
static func lift_direction(flow: Vector2, chord: Vector2) -> Vector2:
	var n := flow * flow.dot(chord) - chord
	if n.length_squared() < 1e-12:
		return Vector2.ZERO
	return n.normalized()


## Angle (0..PI) entre deux vecteurs unitaires.
static func incidence(flow: Vector2, chord: Vector2) -> float:
	return acos(clampf(flow.dot(chord), -1.0, 1.0))
