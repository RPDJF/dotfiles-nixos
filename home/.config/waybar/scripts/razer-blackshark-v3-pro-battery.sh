#!/usr/bin/env bash

status_json=$(blackshark-ctl status 2>/dev/null)

if [ -n "$status_json" ]; then
    connected=$(echo "$status_json" |
        grep -o '"connected": *[^,}]*' |
        awk '{print $2}')

    if [ "$connected" = "true" ]; then
        battery=$(echo "$status_json" |
            grep -o '"battery_percentage": *[^,}]*' |
            awk '{print $2}')

        echo "${battery:-N/A}%"
        exit 0
    fi
fi

echo "--"
