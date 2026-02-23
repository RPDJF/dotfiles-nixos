#!/usr/bin/env bash

# wait for hyprland to start
until hyprctl monitors >/dev/null 2>&1; do
    sleep 0.2
done

# Prevent infinite re-exec FIRST
IS_PINNED=0
if [[ "$1" == "--pinned" ]]; then
    echo "Running pinned."
    IS_PINNED=1
else
    # Only attempt pinning if not already pinned
    if lscpu | grep -qi " 9950X3D "; then
        echo "X3D CPU detected. Pinning to cores 16-31."
        exec taskset -c 16-31 bash "$0" --pinned
    fi
fi

set -euo pipefail

bash "$HOME/.scripts/hyprLiveWallpaperFetcher.sh"

# Configuration
WALLPAPER_DIR="$HOME/.wallpapers"
RAM_DIR="/dev/shm/hypr-wallpaper"
INTERVAL=180 # Change wallpaper every 3 minutes

MPV_OPTIONS="--loop=inf --no-audio --gpu-context=wayland --cache-secs=3600 --framedrop=vo --fps=30"

# Adjust hwdec based on pinned
if [[ $IS_PINNED -eq 1 ]]; then
    MPV_OPTIONS+=" --hwdec=no"
else
    MPV_OPTIONS+=" --hwdec=auto"
fi

# Get monitor info once per loop
get_monitors_info() {
    hyprctl monitors | grep -oP '^Monitor \K\S+'
}

get_monitor_info() {
    local monitor=$1
    local info=$(hyprctl monitors | grep -A 20 "$monitor")
    local resolution=$(echo "$info" | grep -oP '\d{4}x\d{4}' | head -n 1)
    local transform=$(echo "$info" | grep -oP 'transform: \K\d+')
    echo "$resolution $transform"
}

get_video_resolution() {
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$1"
}

mkdir -p $RAM_DIR

while true; do
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) | shuf -n 1)

    for MONITOR in $(get_monitors_info); do
        SCREEN_RESOLUTION=$(get_monitor_info "$MONITOR" | cut -d' ' -f1)
        TRANSFORM=$(get_monitor_info "$MONITOR" | cut -d' ' -f2)

        # TODO: handle transforms properly (fill video to cover entire screen)

        # TODO: implement a solution for weaker hardware | lower screen resolutions

        if [[ "$WALLPAPER" =~ \.(mp4|webm)$ ]]; then
            VIDEO_RESOLUTION=$(get_video_resolution "$WALLPAPER")
        fi

        pkill -f "mpvpaper $MONITOR" || true
            mpvpaper "$MONITOR" "$WALLPAPER" --mpv-options "$MPV_OPTIONS" &
    done
    sleep "$INTERVAL"
done