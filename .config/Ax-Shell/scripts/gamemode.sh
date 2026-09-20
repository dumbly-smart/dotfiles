#!/usr/bin/env sh

# A reversible gaming mode for Hyprland.  Ax-Shell consumes `check` as t/f.
USER_ID=$(id -u)
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/ax-shell-gamemode-${USER_ID}"
ACTIVE_FILE="$STATE_DIR/active"
PROFILE_FILE="$STATE_DIR/power-profile"
INHIBITOR_FILE="$STATE_DIR/inhibitor.pid"

notify() {
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -a "Gaming Mode" "$1" "$2" >/dev/null 2>&1 || true
}

is_active() {
    [ -f "$ACTIVE_FILE" ]
}

start_inhibitor() {
    command -v systemd-inhibit >/dev/null 2>&1 || return 0
    systemd-inhibit --what=idle --mode=block --who="Gaming Mode" \
        --why="Preventing sleep while gaming" sleep infinity >/dev/null 2>&1 &
    echo "$!" > "$INHIBITOR_FILE"
}

stop_inhibitor() {
    [ -r "$INHIBITOR_FILE" ] || return 0
    inhibitor_pid=$(cat "$INHIBITOR_FILE")
    case "$inhibitor_pid" in
        *[!0-9]*|'') return 0 ;;
    esac
    # Only stop the process created by this script.
    if [ -r "/proc/$inhibitor_pid/cmdline" ] && \
       tr '\000' ' ' < "/proc/$inhibitor_pid/cmdline" | grep -q 'systemd-inhibit'; then
        kill "$inhibitor_pid" 2>/dev/null || true
    fi
}

set_performance_profile() {
    command -v powerprofilesctl >/dev/null 2>&1 || return 0
    old_profile=$(powerprofilesctl get 2>/dev/null) || return 0
    echo "$old_profile" > "$PROFILE_FILE"
    powerprofilesctl list 2>/dev/null | grep -q 'performance' || return 0
    powerprofilesctl set performance >/dev/null 2>&1 || true
}

restore_power_profile() {
    [ -s "$PROFILE_FILE" ] || return 0
    command -v powerprofilesctl >/dev/null 2>&1 || return 0
    old_profile=$(cat "$PROFILE_FILE")
    case "$old_profile" in
        power-saver|balanced|performance)
            powerprofilesctl set "$old_profile" >/dev/null 2>&1 || true
            ;;
    esac
}

enable() {
    is_active && return 0
    mkdir -p "$STATE_DIR" || exit 1

    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0" >/dev/null || {
            rmdir "$STATE_DIR" 2>/dev/null || true
            notify "Could not enable" "Hyprland did not accept the gaming-mode settings."
            return 1
        }
    : > "$ACTIVE_FILE"
    set_performance_profile
    start_inhibitor
    notify "Enabled" "Performance profile active; effects, animations, and idle sleep disabled."
}

disable() {
    is_active || return 0
    stop_inhibitor
    restore_power_profile
    hyprctl reload >/dev/null
    rm -f "$ACTIVE_FILE" "$PROFILE_FILE" "$INHIBITOR_FILE"
    rmdir "$STATE_DIR" 2>/dev/null || true
    notify "Disabled" "Your previous desktop and power settings were restored."
}

check() {
    if is_active; then
        echo "t"
        return 0
    fi
    echo "f"
    return 1
}

case "${1:-toggle}" in
    on|enable)  enable ;;
    off|disable) disable ;;
    check|status) check ;;
    toggle)
        if is_active; then disable; else enable; fi
        ;;
    *)
        echo "Usage: $0 [toggle|on|off|check]" >&2
        exit 2
        ;;
esac
