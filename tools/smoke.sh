#!/usr/bin/env bash
# Lance la scène principale sans interface pendant quelques secondes et échoue
# si Godot affiche des erreurs de script.
set -euo pipefail
source "$(dirname "$0")/_godot.sh"
godot_import
log="$(mktemp)"
"$GODOT" --headless --path "$ROOT/game" --quit-after 300 2>&1 | tee "$log"
if grep -E "SCRIPT ERROR|ERROR:|Parse Error" "$log" >/dev/null; then
	echo "Des erreurs ont été détectées." >&2
	exit 1
fi
echo "Scène principale OK."
