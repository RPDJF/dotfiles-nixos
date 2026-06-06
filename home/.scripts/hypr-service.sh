#!/usr/bin/env bash

# --- Configuration ---
name="$1"     # human-readable service name
shift
cmd="$@"      # command to run
max_attempts=10
logfile="$HOME/.cache/hypr-startup.log"
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
    echo "[$(date '+%H:%M:%S')] Attempt $attempt: $name" >> "$logfile"
    if eval "$cmd"; then
        echo "[$(date '+%H:%M:%S')] $name started successfully" >> "$logfile"
        trim_log
        exit 0
    fi
    sleep 1
    attempt=$((attempt + 1))
done

# --- If we reach here, service failed ---
echo "[$(date '+%H:%M:%S')] $name FAILED after $max_attempts attempts" >> "$logfile"
notify-send "Hyprland service failed" "$name failed to start after $max_attempts attempts"
trim_log
exit 1
