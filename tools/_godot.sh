# Fonctions communes aux scripts tools/*.sh (à sourcer).
# GODOT : chemin du binaire Godot 4.7 (par défaut `godot` dans le PATH).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-godot}"

if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "Godot introuvable : installe Godot 4.7 ou définis GODOT=/chemin/vers/godot" >&2
	exit 1
fi

# Importe le projet (régénère le cache des class_name) si nécessaire.
godot_import() {
	if [[ ! -f "$ROOT/game/.godot/global_script_class_cache.cfg" ]] \
		|| [[ -n "$(find "$ROOT/game" -name '*.gd' -newer "$ROOT/game/.godot/global_script_class_cache.cfg" -print -quit)" ]]; then
		"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
	fi
}
