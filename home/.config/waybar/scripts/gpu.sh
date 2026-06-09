#!/usr/bin/env bash

# NVIDIA
if command -v nvidia-smi >/dev/null 2>&1; then
    read used total <<< $(nvidia-smi \
        --query-gpu=memory.used,memory.total \
        --format=csv,noheader,nounits | head -n1 | tr ',' ' ')

    pct=$((used * 100 / total))

    printf '{"text":"󰢮 %s%%","tooltip":"VRAM %.1f/%.1f GiB"}\n' \
        "$pct" \
        "$(awk "BEGIN{print $used/1024}")" \
        "$(awk "BEGIN{print $total/1024}")"

    exit 0
fi

# AMD
for card in /sys/class/drm/card*/device; do
    if [[ -f "$card/mem_info_vram_used" && -f "$card/mem_info_vram_total" ]]; then
        used=$(cat "$card/mem_info_vram_used")
        total=$(cat "$card/mem_info_vram_total")

        pct=$((used * 100 / total))

        usedg=$(awk "BEGIN{printf \"%.1f\", $used/1024/1024/1024}")
        totalg=$(awk "BEGIN{printf \"%.1f\", $total/1024/1024/1024}")

        printf '{"text":"󰢮 %s%%","tooltip":"VRAM %s/%s GiB"}\n' \
            "$pct" "$usedg" "$totalg"

        exit 0
    fi
done

# Intel / fallback
printf '{"text":"󰢮 N/A","tooltip":"GPU memory unavailable"}\n'