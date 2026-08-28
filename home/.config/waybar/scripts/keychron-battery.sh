#!/usr/bin/env bash

# Run the keychron-battery command
output=$(keychron-battery 2>/dev/null)

# Check if the output contains "Active"
if echo "$output" | grep -q "Active"; then
    # Extract the percentage (e.g., "100%") following the battery icon 󰁹
    # Adjust awk field positioning based on your exact CLI output layout
    battery=$(echo "$output" | grep -oP '\d+%' | head -n 1)
    
    # Print format for waybar: keyboard icon + battery percentage
    echo "󰌌 ${battery:-N/A}"
else
    # Output nothing so Waybar hides the module
    exit 0
fi
