#!/usr/bin/env bash

output=$(keychron-battery 2>/dev/null)

if echo "$output" | grep -q "Active"; then
    battery=$(echo "$output" | grep -oP '\d+%' | head -n 1)
    echo "${battery:-N/A}"
    exit 0
fi

echo "--"
