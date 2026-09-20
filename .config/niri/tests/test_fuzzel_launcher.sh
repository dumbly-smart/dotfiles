#!/usr/bin/env bash
set -euo pipefail

config="$HOME/.config/niri/config.kdl"
fuzzel_config="$HOME/.config/fuzzel/fuzzel.ini"

if ! command -v fuzzel >/dev/null; then
    echo "fuzzel is not installed; run: sudo pacman -S fuzzel" >&2
    exit 1
fi
test -s "$fuzzel_config"
grep -Fq 'Super+D { spawn "fuzzel" "--show" "drun"; }' "$config"
grep -Fq 'Super+F1 { spawn "/home/xtrmn8/.local/bin/niri-keybinds"; }' "$config"
grep -Fq '"fuzzel", "--dmenu"' "$HOME/.local/bin/niri-keybinds"
grep -Fq '| fuzzel --dmenu' "$HOME/.local/bin/niri-screenshot"
! grep -Fq -- '--no-fuzzy' "$HOME/.local/bin/niri-keybinds"
! grep -Fq -- '--no-fuzzy' "$HOME/.local/bin/hypr-keybinds"
grep -Fq 'layer=overlay' "$fuzzel_config"
grep -Fq 'icons-enabled=yes' "$fuzzel_config"
grep -Fq 'border=e2e2e2ff' "$fuzzel_config"
grep -Fq 'anchor=center' "$fuzzel_config"

echo "fuzzel_launcher=passed"
