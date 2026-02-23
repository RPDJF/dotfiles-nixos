#!/usr/bin/env bash

# Prevent infinite re-exec FIRST
if [[ "$1" == "--pinned" ]]; then
    echo "Running pinned."
else
    # Only attempt pinning if not already pinned
    if lscpu | grep -qi "9950X3D"; then
        echo "X3D CPU detected. Pinning to cores 16-31."
        exec taskset -c 16-31 bash "$0" --pinned
    fi
fi

set -euo pipefail

bash "$HOME/.scripts/hyprLiveWallpaperFetcher.sh"

# Configuration
WALLPAPER_DIR="$HOME/.wallpapers"
INTERVAL=5
MPV_OPTIONS="--scale=bilinear --loop=inf --no-audio --hwdec=no --video-sync=display-resample --gpu-context=wayland"

pkill -f "mpvpaper" || true

# Get monitor resolution and transform
get_monitor_info() {
    monitor=$1
    info=$(hyprctl monitors | grep -A 20 "$monitor")
    resolution=$(echo "$info" | grep -oP '\d{4}x\d{4}' | head -n 1)
    transform=$(echo "$info" | grep -oP 'transform: \K\d+')
    echo "$resolution $transform"
}

# Get video resolution
get_video_resolution() {
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$1"
}

# Calculate zoom factor
calculate_zoom() {
    screen=$1
    video=$2
    screen_width=$(echo "$screen" | cut -d'x' -f1)
    screen_height=$(echo "$screen" | cut -d'x' -f2)
    video_width=$(echo "$video" | cut -d',' -f1)
    video_height=$(echo "$video" | cut -d',' -f2)
    zoom_width=$(echo "$screen_width / $video_width" | bc -l)
    zoom_height=$(echo "$screen_height / $video_height" | bc -l)
    echo $(echo "$zoom_width > $zoom_height" | bc)
}

# Main loop
while true; do
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) | shuf -n 1)
    for MONITOR in $(hyprctl monitors | grep -oP '^Monitor \K\S+'); do
        SCREEN_RESOLUTION=$(get_monitor_info "$MONITOR" | cut -d' ' -f1)
        TRANSFORM=$(get_monitor_info "$MONITOR" | cut -d' ' -f2)

        # TODO: handle transforms properly (fill video to cover entire screen)

        if [[ "$WALLPAPER" =~ \.(mp4|webm)$ ]]; then
            VIDEO_RESOLUTION=$(get_video_resolution "$WALLPAPER")
            ZOOM=$(calculate_zoom "$SCREEN_RESOLUTION" "$VIDEO_RESOLUTION")
            MPV_OPTIONS="--fs --scale=bilinear --loop=inf --no-audio --hwdec=no --video-sync=display-resample --gpu-context=wayland --video-zoom=$ZOOM"
        fi

        #pkill -f "mpvpaper $MONITOR" || true
        mpvpaper "$MONITOR" "$WALLPAPER" --mpv-options "$MPV_OPTIONS" &

    done
    sleep "$INTERVAL"
done