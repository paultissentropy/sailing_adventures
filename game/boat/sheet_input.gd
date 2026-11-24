class_name SheetInput
extends RefCounted
## Détecte le double appui rapide sur « choquer », qui choque l'écoute en grand.

## Délai maximal entre deux appuis (s).
const DOUBLE_TAP_S := 0.3

var _last_press := -INF


## À appeler à chaque nouvel appui, avec l'heure courante (s).
## Retourne vrai si c'est le second appui d'un double appui.
func press(now: float) -> bool:
	var double := now - _last_press <= DOUBLE_TAP_S
	# Un triple appui ne compte pas pour deux doubles.
	_last_press = -INF if double else now
	return double
