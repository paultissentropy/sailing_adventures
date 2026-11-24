extends Node
## Autoload : déclare les actions du jeu.
##
## Les touches sont des touches *physiques* (position sur le clavier, nommée selon le
## QWERTY) : KEY_A désigne la touche Q d'un clavier AZERTY. Le jeu fonctionne donc
## de la même façon sur tous les claviers, et `key_label()` affiche le nom imprimé
## sur le clavier du joueur.

const ACTIONS := {
	"helm_left": [KEY_LEFT],
	"helm_right": [KEY_RIGHT],
	# AZERTY : S borde la GV, Z la choque ; Q borde le foc, A le choque.
	"main_in": [KEY_S],
	"main_out": [KEY_W],
	"jib_in": [KEY_A],
	"jib_out": [KEY_Q],
	"look_port": [KEY_J],
	"look_starboard": [KEY_L],
	"camera_toggle": [KEY_C],
	"debug_toggle": [KEY_F1],
	"instruments_toggle": [KEY_F2],
	"help_toggle": [KEY_H],
	"reset_boat": [KEY_R],
	"wind_left": [KEY_1],
	"wind_right": [KEY_2],
	"wind_down": [KEY_3],
	"wind_up": [KEY_4],
}

const SYMBOLS := {
	KEY_LEFT: "←",
	KEY_RIGHT: "→",
	KEY_UP: "↑",
	KEY_DOWN: "↓",
	KEY_SPACE: "Espace",
	# Rangée des chiffres : sur AZERTY ces touches portent aussi le chiffre.
	KEY_1: "1",
	KEY_2: "2",
	KEY_3: "3",
	KEY_4: "4",
}


func _enter_tree() -> void:
	install()


static func install() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: Key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


## Nom des touches d'une action, tel qu'imprimé sur le clavier du joueur.
static func key_label(action: String) -> String:
	var names := PackedStringArray()
	for key: Key in ACTIONS[action]:
		names.append(_label(key))
	return " / ".join(names)


static func _label(physical: Key) -> String:
	if SYMBOLS.has(physical):
		return SYMBOLS[physical]
	var shown := physical
	if DisplayServer.get_name() != "headless":
		shown = DisplayServer.keyboard_get_label_from_physical(physical)
		if shown == KEY_NONE:
			shown = physical
	return OS.get_keycode_string(shown)
