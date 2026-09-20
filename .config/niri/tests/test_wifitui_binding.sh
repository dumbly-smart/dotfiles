#!/usr/bin/env bash
set -euo pipefail

niri_config="${HOME}/.config/niri/config.kdl"
wifitui="${HOME}/.local/bin/wifitui"
theme="${HOME}/.config/wifitui/theme.toml"

test -x "$wifitui"
test -f "$theme"
grep -q '^Primary = \["#FFFFFF", "#FFFFFF"\]$' "$theme"
grep -q '^TitleIcon = ""$' "$theme"
grep -q '^NetworkSecureIcon = ""$' "$theme"
"$wifitui" --version | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
grep -q 'Super+W { spawn "alacritty" "--class" "wifitui" "--title" "Wi-Fi" "--command" "/home/xtrmn8/.local/bin/wifitui" "--theme=/home/xtrmn8/.config/wifitui/theme.toml"; }' "$niri_config"
! grep -q 'Super+W.*connectivity-panel' "$niri_config"
