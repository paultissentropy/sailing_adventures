#!/usr/bin/env bash
# Banc d'essai : manœuvres types sur chaque bateau, comparées aux références.
# Écrit le bulletin dans docs/banc-essai.md.
set -euo pipefail
source "$(dirname "$0")/_godot.sh"
godot_import
"$GODOT" --headless --path "$ROOT/game" -s res://tests/bench.gd -- "$ROOT/docs/banc-essai.md"
