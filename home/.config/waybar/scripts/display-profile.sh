#!/usr/bin/env bash
set -euo pipefail

profile=${1:?Expected a display profile}
action=${2:-status}

apply_profile() {
    case "$profile" in
        all)
            wlr-randr \
                --output HDMI-A-2 --on --mode 3840x2160@119.879997Hz --pos 0,0 \
                --output DP-4 --on --mode 2560x1440@164.998993Hz --pos 3840,0 \
                --output DP-3 --on --mode 3840x2160@240.016006Hz --pos 6400,0
            ;;
        tv)
            wlr-randr \
                --output HDMI-A-2 --on --mode 3840x2160@119.879997Hz --pos 0,0 \
                --output DP-4 --off \
                --output DP-3 --off
            ;;
        monitors)
            wlr-randr \
                --output HDMI-A-2 --off \
                --output DP-4 --on --mode 2560x1440@164.998993Hz --pos 0,0 \
                --output DP-3 --on --mode 3840x2160@240.016006Hz --pos 2560,0
            ;;
        *)
            printf 'Unknown display profile: %s\n' "$profile" >&2
            return 2
            ;;
    esac

}

report_profile() {
    local states tv_enabled dp3_enabled dp4_enabled active=false text tooltip

    states=$(wlr-randr --json | jq -c '
        map({key: .name, value: .enabled}) | from_entries
    ')
    tv_enabled=$(jq -r '.["HDMI-A-2"] // false' <<< "$states")
    dp3_enabled=$(jq -r '.["DP-3"] // false' <<< "$states")
    dp4_enabled=$(jq -r '.["DP-4"] // false' <<< "$states")

    if [[ "$tv_enabled" == true && "$dp3_enabled" == true && "$dp4_enabled" == true ]]; then
        active=$([[ "$profile" == all ]] && echo true || echo false)
    elif [[ "$tv_enabled" == true && "$dp3_enabled" == false && "$dp4_enabled" == false ]]; then
        active=$([[ "$profile" == tv ]] && echo true || echo false)
    elif [[ "$tv_enabled" == false && "$dp3_enabled" == true && "$dp4_enabled" == true ]]; then
        active=$([[ "$profile" == monitors ]] && echo true || echo false)
    fi

    case "$profile" in
        all)
            text='📺🖥️'
            tooltip='TV + Monitors
LG TV 4K/120 · VG27A 1440p/165 · XG32UCWMG 4K/240'
            ;;
        tv)
            text='📺'
            tooltip='TV Only
LG TV 3840x2160 at 120 Hz'
            ;;
        monitors)
            text='🖥️🖥️'
            tooltip='Monitors Only
VG27A 2560x1440 at 165 Hz
XG32UCWMG 3840x2160 at 240 Hz'
            ;;
        *)
            printf 'Unknown display profile: %s\n' "$profile" >&2
            return 2
            ;;
    esac

    if [[ "$active" == true ]]; then
        jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip, class: "active"}'
    else
        jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip, class: "inactive"}'
    fi
}

case "$action" in
    set)
        apply_profile
        ;;
    status)
        report_profile
        ;;
    *)
        printf 'Unknown action: %s\n' "$action" >&2
        exit 2
        ;;
esac