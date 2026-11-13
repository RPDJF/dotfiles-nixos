#!/usr/bin/env bash

mode="${1:-}"
cpu_model=$(lscpu | grep -i "model name" | cut -d: -f2 | xargs)
total_cores=$(nproc)
half_cores=$((total_cores / 2))
half_max=$((half_cores - 1))
max_index=$((total_cores - 1))

if [[ "$mode" == "vcache" ]]; then
    if echo "$cpu_model" | grep -qi "9950x3d"; then
        echo "0-15"
    elif echo "$cpu_model" | grep -qi "x3d" && ! echo "$cpu_model" | grep -qi "x3dv2"; then
        echo "0-$half_max"
    else
        echo "0-$max_index"
    fi
elif [[ "$mode" == "frequency" ]]; then
    if echo "$cpu_model" | grep -qi "9950x3d"; then
        echo "16-$max_index"
    elif echo "$cpu_model" | grep -qi "x3d" && ! echo "$cpu_model" | grep -qi "x3dv2"; then
        echo "$half_cores-$max_index"
    else
        echo "0-$max_index"
    fi
else
    echo "0-$max_index"
fi
