#!/usr/bin/env bash
set -euo pipefail

niri_config="${HOME}/.config/niri/config.kdl"
service="${HOME}/.config/systemd/user/skwd-walld.service"
picker_config="${HOME}/.config/skwd-wall-v2/config.json"

test -x "$(command -v skwd-wall-v2)"
systemctl --user cat skwd-walld.service >/dev/null
grep -q 'skwd-walld.service' "$niri_config"
grep -q 'skwd-wall-v2' "$niri_config"
grep -q 'Super+Shift+Y { spawn "skwd-wall-v2"; }' "$niri_config"
! grep -q 'systemctl --user start awww.service' "$niri_config"
! grep -q 'spawn-sh .*awww img' "$niri_config"
grep -q 'place-within-backdrop true' "$niri_config"
test -f "$picker_config"
test "$(jq -r '.components.wallpaperSelector.displayMode' "$picker_config")" = "slices"
test "$(jq -r '.general.filterBarAlwaysVisible' "$picker_config")" = "true"
test "$(jq -r '.launch.animation' "$picker_config")" = "zoom"
test "$(jq -r '.videoPreview.enabled' "$picker_config")" = "true"
test "$(jq -r '.filterBar.visualStyle' "$picker_config")" = "slices"
test "$(jq -r '.filterBar.show.colors' "$picker_config")" = "true"
test "$(jq -r '.filterBar.show.favourites' "$picker_config")" = "true"
test "$(jq -r '.filterBar.show.folder' "$picker_config")" = "true"
test "$(jq -r '.filterBar.show.resolution' "$picker_config")" = "true"
test "$(jq -r '.filterBar.show.tag' "$picker_config")" = "true"
test "$(jq -r '.filterBar.show.type.image' "$picker_config")" = "true"
test "$(jq -r '.filterBar.show.type.video' "$picker_config")" = "true"

echo "skwd_wall_integration=passed"
