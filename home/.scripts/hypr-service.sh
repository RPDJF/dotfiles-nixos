#!/usr/bin/env bash

# -- Logging --
logfile="$HOME/.cache/hypr-startup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$logfile"
}

# --- CPU Pinning Check ---
if [ "$1" == "--pinned" ]; then
    echo "Running pinned."
    shift
    log "================================"
    log "$1 Started in PINNED mode (cores 16-31)"
elif lscpu | grep -qi " 9950X3D "; then
    echo "X3D CPU detected. Pinning to cores 16-31."
    if [ -x "$0" ]; then
        exec taskset -c 16-31 "$0" --pinned "$@"
    else
        exec taskset -c 16-31 bash "$0" --pinned "$@"
    fi

fi

# --- Configuration ---
name="$1"     # human-readable service name
shift
cmd="$@"      # command to run
max_attempts=10
max_lines=200   # maximum lines in log

# --- Helper: trim logfile ---
trim_log() {
    if [ -f "$logfile" ]; then
        lines=$(wc -l < "$logfile")
        if [ "$lines" -gt "$max_lines" ]; then
            tail -n "$max_lines" "$logfile" > "${logfile}.tmp" && mv "${logfile}.tmp" "$logfile"
        fi
    fi
}

# --- Retry loop ---
attempt=1
while [ $attempt -le $max_attempts ]; do
    log "$name Attempt $attempt: $name"
    if eval "$cmd"; then
        log "$name started successfully"
        trim_log
        exit 0
    fi
    sleep 1
    attempt=$((attempt + 1))
done

# --- If we reach here, service failed ---
log "$name FAILED after $max_attempts attempts" >> "$logfile"
notify-send "Hyprland service failed" "$name failed to start after $max_attempts attempts"
trim_log
exit 1