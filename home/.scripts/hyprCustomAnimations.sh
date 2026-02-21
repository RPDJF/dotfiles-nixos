#!/usr/bin/env bash

LOGFILE="$HOME/.cache/oled-care.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

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

# Log run mode
if [[ "$1" == "--pinned" ]]; then
    log "Started in PINNED mode (cores 16-31)"
else
    log "Started in NORMAL mode"
fi

# OLED care animations
while true; do
  for i in $(seq 0 3 359); do
    hyprctl keyword general:col.active_border "rgba(c6a0f6cc) rgba(b57a3acc) ${i}deg"

    # subtle opacity flicker
    opacity=$(echo "0.88 + 0.02 * s($i * 0.01745)" | bc -l)
    hyprctl keyword decoration:active_opacity $opacity
    hyprctl keyword decoration:inactive_opacity $(echo "$opacity - 0.2" | bc)

    sleep 0.03
  done
done
