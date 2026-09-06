#!/usr/bin/env bash

# wait for hyprland
until hyprctl monitors >/dev/null 2>&1; do
    sleep 0.2
done

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

# WALLPAPERS
shopt -s nullglob
WALLPAPERS=("$WALLPAPER_DIR"/*.{mp4,webm})

(( ${#WALLPAPERS[@]} )) || {
    echo "No wallpapers found"
    exit 1
}

# TRACK LAST WALLPAPER (avoid useless reload)
LAST=""

# STOP mpvpaper
stop_wallpaper() {
    echo "Stopping existing mpvpaper instances..."

    pkill -TERM -f mpvpaper 2>/dev/null || true
    sleep 0.5
    pkill -KILL -f mpvpaper 2>/dev/null || true
}

# START MPVPAPER INSTANCE
start_wallpaper() {
    local file="$1"

    stop_wallpaper

    mpvpaper \
        ALL \
        "$file" \
        --no-audio \
        --hwdec=auto \
        --mpv-options="loop-file=inf --profile=fast --no-config --keep-open=yes" \
        >/dev/null 2>&1 &
}

# CLEANUP ON EXIT
cleanup() {
    echo "Cleaning up wallpaper..."
    stop_wallpaper
}

trap cleanup EXIT INT TERM

is_gaming() {
    if pgrep -f "SteamLaunch AppId=" > /dev/null; then
        return 0
    else
        return 1
    fi
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