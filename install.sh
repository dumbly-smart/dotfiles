#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TARGET_HOME=${DOTFILES_HOME:-$HOME}
PACKAGE_MANAGER=${DOTFILES_PACKAGE_MANAGER:-}
DRY_RUN=false
SKIP_PACKAGES=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Install this repository's desktop configuration into the current user's home.

Options:
  --dry-run        Show package and file actions without changing the system.
  --skip-packages Skip system package installation and verification.
  -h, --help       Show this help.

Environment:
  DOTFILES_HOME              Override the destination home directory.
  DOTFILES_PACKAGE_MANAGER   Override detection (pacman, apt, dnf, zypper, mock).
EOF
}

log() {
  printf '[dotfiles] %s\n' "$*"
}

die() {
  printf '[dotfiles] ERROR: %s\n' "$*" >&2
  exit 1
}

run() {
  if "$DRY_RUN"; then
    printf '[dotfiles] DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

while (($#)); do
  case $1 in
    --dry-run) DRY_RUN=true ;;
    --skip-packages) SKIP_PACKAGES=true ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

[[ -d $REPO_ROOT/.config ]] || die "run this script from a complete dotfiles checkout"
[[ -d $TARGET_HOME ]] || die "target home does not exist: $TARGET_HOME"

if "$DRY_RUN"; then
  log 'DRY RUN: no changes will be made'
fi

detect_package_manager() {
  [[ -n $PACKAGE_MANAGER ]] && return
  if command -v pacman >/dev/null 2>&1; then
    PACKAGE_MANAGER=pacman
  elif command -v apt-get >/dev/null 2>&1; then
    PACKAGE_MANAGER=apt
  elif command -v dnf >/dev/null 2>&1; then
    PACKAGE_MANAGER=dnf
  elif command -v zypper >/dev/null 2>&1; then
    PACKAGE_MANAGER=zypper
  else
    die 'unsupported distribution: could not find pacman, apt-get, dnf, or zypper'
  fi
}

declare -a REQUIRED_COMMANDS=(
  Hyprland niri waybar kitty alacritty fuzzel mako rofi cava matugen
  nvim zellij yazi btop mpv wl-copy grim slurp playerctl brightnessctl
  git rsync
)

declare -A PACKAGE_FOR_COMMAND=(
  [Hyprland]=hyprland [niri]=niri [waybar]=waybar [kitty]=kitty
  [alacritty]=alacritty [fuzzel]=fuzzel [mako]=mako [rofi]=rofi
  [cava]=cava [matugen]=matugen [nvim]=neovim [zellij]=zellij
  [yazi]=yazi [btop]=btop [mpv]=mpv [wl-copy]=wl-clipboard
  [grim]=grim [slurp]=slurp [playerctl]=playerctl
  [brightnessctl]=brightnessctl [git]=git [rsync]=rsync
)

missing_packages() {
  local command_name package_name
  local -a missing=()
  if [[ $PACKAGE_MANAGER == mock ]]; then
    for command_name in "${REQUIRED_COMMANDS[@]}"; do
      package_name=${PACKAGE_FOR_COMMAND[$command_name]}
      [[ " ${missing[*]} " == *" $package_name "* ]] || missing+=("$package_name")
    done
    printf '%s\n' "${missing[@]}"
    return
  fi
  for command_name in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      package_name=${PACKAGE_FOR_COMMAND[$command_name]}
      [[ " ${missing[*]} " == *" $package_name "* ]] || missing+=("$package_name")
    fi
  done
  printf '%s\n' "${missing[@]}"
}

as_root() {
  if ((EUID == 0)); then
    "$@"
  else
    command -v sudo >/dev/null 2>&1 || die 'sudo is required to install system packages'
    sudo "$@"
  fi
}

install_packages() {
  detect_package_manager
  local -a missing
  mapfile -t missing < <(missing_packages)
  if ((${#missing[@]} == 0)); then
    log 'all required commands are already installed'
    return
  fi

  log "missing packages: ${missing[*]}"
  case $PACKAGE_MANAGER in
    mock)
      log "mock package manager would install: ${missing[*]}"
      ;;
    pacman)
      run as_root pacman -Syu --needed --noconfirm "${missing[@]}"
      ;;
    apt)
      run as_root apt-get update
      run as_root apt-get install -y "${missing[@]}"
      ;;
    dnf)
      run as_root dnf install -y "${missing[@]}"
      ;;
    zypper)
      run as_root zypper --non-interactive install "${missing[@]}"
      ;;
    *)
      die "unsupported package manager: $PACKAGE_MANAGER"
      ;;
  esac
}

copy_dotfiles() {
  command -v rsync >/dev/null 2>&1 || die 'rsync is required to copy dotfiles; install it or omit --skip-packages'
  local suffix
  suffix=".bak.$(date +%Y%m%d%H%M%S)"
  log "copying configuration to $TARGET_HOME"
  run rsync -a --backup --suffix="$suffix" \
    --exclude='.git/' \
    --exclude='install.sh' \
    --exclude='README.md' \
    --exclude='tests/' \
    --exclude='.gitignore' \
    "$REPO_ROOT/" "$TARGET_HOME/"
  log "existing files were backed up with suffix $suffix"
}

verify_desktop_commands() {
  local command_name
  for command_name in Hyprland niri; do
    command -v "$command_name" >/dev/null 2>&1 || die "$command_name is still unavailable after package installation"
  done
}

if "$SKIP_PACKAGES"; then
  log 'skipping package installation by request'
else
  install_packages
  if ! "$DRY_RUN"; then
    verify_desktop_commands
  fi
fi

if "$DRY_RUN"; then
  log "would copy dotfiles into $TARGET_HOME and back up collisions"
else
  copy_dotfiles
  cat <<'EOF'
[dotfiles] Setup complete.
[dotfiles] Log out and select Hyprland or Niri from your display manager.
[dotfiles] If no graphical login is installed, start either compositor from a TTY.
EOF
fi
