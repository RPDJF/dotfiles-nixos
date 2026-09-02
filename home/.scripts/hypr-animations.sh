#!/usr/bin/env bash

LOGFILE="$HOME/.cache/oled-care.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# OLED care animations
while true; do
  for i in $(seq 0 8 359); do
    hyprctl eval "hl.config({ general = { col = { active_border = { colors = { \"rgba(c6a0f6cc)\", \"rgba(b57a3acc)\" }, angle = ${i} } } } })"

    # subtle opacity flicker
    opacity=$(echo "0.95 + 0.02 * s($i * 0.01745)" | bc -l)
    hyprctl eval "hl.config({ decoration = { active_opacity = ${opacity} } })"
    hyprctl eval "hl.config({ decoration = { inactive_opacity = $(echo "$opacity - 0.2" | bc) } })"

    sleep 0.03
  done
done

