#!/usr/bin/env bash

# wait for hyprland
until hyprctl monitors >/dev/null 2>&1; do
    sleep 0.2
done

# CPU pinning
if [[ "$1" == "--pinned" ]]; then
    echo "Running pinned."
else
    if lscpu | grep -qi " 9950X3D "; then
        echo "X3D CPU detected. Pinning to cores 16-31."
        exec taskset -c 16-31 bash "$0" --pinned
    fi
fi

set -euo pipefail

# START wallpaper fetcher first
FETCHER_SCRIPT="$HOME/.scripts/hypr-live-wallpaper-fetcher.sh"

if [[ -x "$FETCHER_SCRIPT" ]]; then
    echo "Starting wallpaper fetcher..."

    "$FETCHER_SCRIPT"

    echo "Wallpaper fetcher finished."
else
    echo "Missing or not executable: $FETCHER_SCRIPT"
    exit 1
fi

WALLPAPER_DIR="$HOME/.wallpapers/optimized"
INTERVAL=180

# MONITOR CACHE
mapfile -t MONITORS < <(hyprctl monitors | awk '/Monitor/ {print $2}')

# WALLPAPERS
shopt -s nullglob
WALLPAPERS=("$WALLPAPER_DIR"/*.{mp4,webm})

(( ${#WALLPAPERS[@]} )) || {
    echo "No wallpapers found"
    exit 1
}

# TRACK LAST WALLPAPER (avoid useless reload)
LAST=""

# STOP mpvpaper SAFELY
stop_wallpaper() {
    pkill -TERM -f mpvpaper 2>/dev/null || true
    sleep 0.2
}

# START WALLPAPER (ALL MONITORS)
start_wallpaper() {
    local file="$1"

    stop_wallpaper

    for monitor in "${MONITORS[@]}"; do
        mpvpaper "$monitor" "$file" \
            --no-audio \
            --hwdec=auto-safe \
            --mpv-options="loop-file=inf --profile=fast --no-config --panscan=1.0 --keep-open=yes --video-sync=display-resample --framedrop=vo" \
            >/dev/null 2>&1 &
    done
}

# LIGHTWEIGHT GAMING CHECK
is_gaming() {
    pgrep -f "steam_app\|proton\|wine" >/dev/null 2>&1 && return 0
    hyprctl activewindow | grep -q "fullscreen: 1" && return 0
    return 1
}

# MAIN LOOP
while true; do

    # Skip switching during gaming
    if is_gaming; then
        echo "Gaming detected → skipping wallpaper switch"
        sleep "$INTERVAL"
        continue
    fi

    WALLPAPER="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"

    # Prevent redundant reload
    if [[ "$WALLPAPER" == "$LAST" ]]; then
        sleep 2
        continue
    fi

    LAST="$WALLPAPER"

    echo "Playing: $WALLPAPER"

    start_wallpaper "$WALLPAPER"

    sleep "$INTERVAL"
done