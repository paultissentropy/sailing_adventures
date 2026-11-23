#!/usr/bin/env bash
# Calcule la polaire du bateau (tools/out/polar.csv) et la trace (docs/img/polaire.png).
set -euo pipefail
source "$(dirname "$0")/_godot.sh"
godot_import
mkdir -p "$ROOT/tools/out"
"$GODOT" --headless --path "$ROOT/game" -s res://tests/polar.gd -- "$ROOT/tools/out/polar.csv"
python3 "$ROOT/tools/plot_polar.py" "$ROOT/tools/out/polar.csv" "$ROOT/docs/img/polaire.png"
