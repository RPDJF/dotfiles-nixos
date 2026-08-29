#!/usr/bin/env bash

next=$(
    hyprctl workspaces |
    awk '/workspace ID/ {id=$3} id > 0 && id ~ /^[0-9]+$/ {print id}' |
    sort -n |
    tail -1
)

next=$((next + 1))

hyprctl dispatch "hl.dsp.focus({ workspace = \"$next\" })"
