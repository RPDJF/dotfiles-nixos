#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROFILE_DIR="$($SCRIPT_DIR/hypr-profile-dir)"
PROFILE_MONITORS_FILE="$PROFILE_DIR/monitors.lua"
REPO_PROFILE_DIR="$REPO_ROOT/home/.config/hypr/hyprland.profiles.d/$(basename "$PROFILE_DIR")"
MONITORS_DIR="$PROFILE_DIR/monitors.d"
SDR_FILE="$MONITORS_DIR/sdr.lua"
HDR_FILE="$MONITORS_DIR/hdr.lua"

if [ ! -f "$SDR_FILE" ]; then
    SDR_FILE="$MONITORS_DIR/sdr.lua.disabled"
fi

if [ ! -f "$HDR_FILE" ]; then
    HDR_FILE="$MONITORS_DIR/hdr.lua.disabled"
fi

RED='\033[0;31m'
NC='\033[0m'

reload_hyprland() {
    if ! command -v hyprctl >/dev/null 2>&1; then
        echo -e "${RED}Error: hyprctl not found${NC}" >&2
        exit 1
    fi

    echo "Reloading Hyprland..."
    hyprctl reload
}

write_monitor_config() {
    local source_file="$1"

    rm -f "$PROFILE_MONITORS_FILE"
    cp "$source_file" "$PROFILE_MONITORS_FILE"

    if [ -d "$REPO_PROFILE_DIR" ]; then
        rm -f "$REPO_PROFILE_DIR/monitors.lua"
        cp "$source_file" "$REPO_PROFILE_DIR/monitors.lua"
    fi
}

if [ ! -d "$PROFILE_DIR" ]; then
    echo -e "${RED}Error: Profile directory not found at $PROFILE_DIR${NC}" >&2
    exit 1
fi

if [ ! -f "$SDR_FILE" ]; then
    echo -e "${RED}Error: SDR config not found at $SDR_FILE${NC}" >&2
    exit 1
fi

if [ ! -f "$HDR_FILE" ]; then
    echo -e "${RED}Error: HDR config not found at $HDR_FILE${NC}" >&2
    exit 1
fi

case "${1,,}" in
    on|hdr)
        write_monitor_config "$HDR_FILE"
        echo "Switched to HDR"
        reload_hyprland
        ;;
    off|sdr)
        write_monitor_config "$SDR_FILE"
        echo "Switched to SDR"
        reload_hyprland
        ;;
    toggle|"")
        if [ -f "$PROFILE_MONITORS_FILE" ] && grep -q 'cm = "hdr"' "$PROFILE_MONITORS_FILE"; then
            write_monitor_config "$SDR_FILE"
            echo "Switched to SDR"
        else
            write_monitor_config "$HDR_FILE"
            echo "Switched to HDR"
        fi
        reload_hyprland
        ;;
    *)
        echo "Usage: $(basename "$0") [on|off|toggle]"
        exit 1
        ;;
esac
