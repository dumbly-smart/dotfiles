#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local needle=$1
  local haystack=$2
  [[ $haystack == *"$needle"* ]] || fail "expected output to contain: $needle"
}

printf '1. dry-run selects missing desktop packages\n'
mkdir -p "$TEST_ROOT/dry-home"
dry_run_output=$(
  DOTFILES_HOME="$TEST_ROOT/dry-home" \
  DOTFILES_PACKAGE_MANAGER=mock \
  "$ROOT_DIR/install.sh" --dry-run 2>&1
)
assert_contains 'hyprland' "$dry_run_output"
assert_contains 'niri' "$dry_run_output"
assert_contains 'DRY RUN' "$dry_run_output"

printf '2. install backs up and copies an existing config\n'
mkdir -p "$TEST_ROOT/home/.config/hypr"
printf 'old-config\n' > "$TEST_ROOT/home/.config/hypr/hyprland.conf"
DOTFILES_HOME="$TEST_ROOT/home" \
  DOTFILES_PACKAGE_MANAGER=mock \
  "$ROOT_DIR/install.sh" --skip-packages >/dev/null

[[ -f "$TEST_ROOT/home/.config/hypr/hyprland.conf" ]] || fail 'hyprland config was not installed'
find "$TEST_ROOT/home/.config/hypr" -maxdepth 1 -name 'hyprland.conf.bak.*' -print -quit | grep -q . || fail 'existing config was not backed up'
[[ -f "$TEST_ROOT/home/.zshrc" ]] || fail 'shell config was not installed'

printf '3. rerun remains successful\n'
DOTFILES_HOME="$TEST_ROOT/home" \
  DOTFILES_PACKAGE_MANAGER=mock \
  "$ROOT_DIR/install.sh" --skip-packages >/dev/null

printf 'PASS\n'
