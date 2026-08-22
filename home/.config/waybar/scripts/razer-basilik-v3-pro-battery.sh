#!/bin/sh

f=$(find /sys/devices -path '*1532:00AB*' -name charge_level -print -quit 2>/dev/null)

[ -n "$f" ] && awk '{ printf "%.0f%%\n", $1 * 100 / 255 }' "$f"

