#!/usr/bin/env bash

output=$(razer-cli -l 2>/dev/null)

if [ -n "$output" ]; then
    charges=$(echo "$output" | grep -A 2 "battery:" | grep "charge:" | awk '{print $2}')
    
    for c in $charges; do
        if [ -n "$c" ] && [ "$c" -gt 0 ] 2>/dev/null; then
            echo "${c}%"
            exit 0
        fi
    done
fi

echo "--"