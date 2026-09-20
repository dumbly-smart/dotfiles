#!/usr/bin/env bash
set -euo pipefail

lua_config="${HOME}/.config/hypr/hyprland.lua"
grep -q 'SUPER + R' "$lua_config"
grep -q 'hl.dsp.exec_cmd.*fabric-cli exec ax-shell' "$lua_config"

binding="$(hyprctl binds -j | jq -c '.[] | select(.key == "R" and .modmask == 64)')"
test -n "$binding"
