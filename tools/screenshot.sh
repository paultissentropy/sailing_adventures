#!/usr/bin/env bash
# Capture d'écran du jeu (ouvre une fenêtre quelques secondes).
# Usage : tools/screenshot.sh [sortie.png] [secondes] [distance] [inclinaison] [rotation] [--debug]
set -euo pipefail
source "$(dirname "$0")/_godot.sh"
godot_import
out="${1:-$ROOT/docs/img/capture.png}"
shift || true
"$GODOT" --path "$ROOT/game" -s res://tests/screenshot.gd -- "$(realpath -m "$out")" "$@"
