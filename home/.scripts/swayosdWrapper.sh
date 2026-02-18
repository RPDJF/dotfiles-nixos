#!/usr/bin/env bash
# ~/bin/swayosd-legacy-wrapper.sh
# Usage: swayosd-legacy-wrapper.sh volume up|down|mute
#        swayosd-legacy-wrapper.sh brightness up|down
#        swayosd-legacy-wrapper.sh media play-pause|next|prev

cmd=$1
action=$2

case "$cmd" in
    volume)
        case "$action" in
            up)   swayosd-client --output-volume=raise ;;
            down) swayosd-client --output-volume=lower ;;
            mute) swayosd-client --output-volume=mute-toggle ;;
            *) echo "unknown volume action: $action" >&2; exit 1 ;;
        esac
        ;;
    brightness)
        case "$action" in
            up)   swayosd-client --brightness=raise ;;
            down) swayosd-client --brightness=lower ;;
            *) echo "unknown brightness action: $action" >&2; exit 1 ;;
        esac
        ;;
    media)
        case "$action" in
            play-pause) swayosd-client --playerctl=play-pause ;;
            next)       swayosd-client --playerctl=next ;;
            prev)       swayosd-client --playerctl=prev ;;
            *) echo "unknown media action: $action" >&2; exit 1 ;;
        esac
        ;;
    *) echo "unknown command: $cmd" >&2; exit 1 ;;
esac
