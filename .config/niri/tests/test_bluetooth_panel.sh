#!/usr/bin/env bash
set -euo pipefail

niri_config="${HOME}/.config/niri/config.kdl"

bluetui_bin="${HOME}/.cargo/bin/bluetui"
bluetui_config="${HOME}/.config/bluetui/config.toml"

test -x "$bluetui_bin"
test -f "$bluetui_config"
grep -q 'Super+B { spawn "alacritty" "--class" "bluetooth-tui" "--title" "Bluetooth"' "$niri_config"
grep -q '"--command" "/home/xtrmn8/.cargo/bin/bluetui" "--config" "/home/xtrmn8/.config/bluetui/config.toml"; }' "$niri_config"
grep -q 'colors.primary.background=\\"#212121\\"' "$niri_config"
grep -q 'colors.primary.foreground=\\"#eeeeee\\"' "$niri_config"
! grep -q 'Super+B.*connectivity-panel' "$niri_config"
! grep -q 'Super+B.*bluetooth-panel' "$niri_config"
! grep -q 'Super+B.*bluetooth-tui"; }' "$niri_config"

"$bluetui_bin" --version >/dev/null
