#!/usr/bin/env bash

# Check status using blackshark-ctl
status_json=$(blackshark-ctl status 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$status_json" ]; then
    # Headset not connected or tool failed
    exit 1
fi

connected=$(echo "$status_json" | grep -o '"connected": *[^,}]*' | awk '{print $2}')

if [ "$connected" = "true" ]; then
    battery=$(echo "$status_json" | grep -o '"battery_percentage": *[^,}]*' | awk '{print $2}')
    echo "${battery}%"
else
    exit 1
fi