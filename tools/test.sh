#!/usr/bin/env bash
# Lance les tests de la simulation, sans interface.
set -euo pipefail
source "$(dirname "$0")/_godot.sh"
godot_import
"$GODOT" --headless --path "$ROOT/game" -s res://tests/run_tests.gd
