#!/usr/bin/env bash
# ~/bin/swayosd-legacy-wrapper.sh
# Usage: swayosd-legacy-wrapper.sh volume up|down|mute
#        swayosd-legacy-wrapper.sh brightness up|down
#        swayosd-legacy-wrapper.sh media play-pause|next|prev

cmd=$1
action=$2

play_sound() {
    # simple debounce: only play if last sound >50ms ago
    last_sound_file="/tmp/.last_volume_sound"
    now=$(date +%s%3N) # milliseconds
    last=$(cat "$last_sound_file" 2>/dev/null || echo 0)
    if (( now - last > 50 )); then
        canberra-gtk-play -i audio-volume-change -d "swayosd" 2>/dev/null &
        echo $now > "$last_sound_file"
    fi
}
case "$cmd" in
    volume)
        case "$action" in
            up)
                swayosd-client --output-volume=raise
                play_sound
                ;;
            down)
                swayosd-client --output-volume=lower
                play_sound
                ;;
            mute)
                swayosd-client --output-volume=mute-toggle
                play_sound
                ;;
            *)
                echo "unknown volume action: $action" >&2
                exit 1
            ;;
        esac
        ;;
    brightness)
        case "$action" in
            up)
                swayosd-client --brightness=raise
                play_sound
                ;;
            down)
                swayosd-client --brightness=lower
                play_sound
                ;;
            *)
                echo "unknown brightness action: $action" >&2
                exit 1
            ;;
        esac
        ;;
    media)
        case "$action" in
            play-pause)
                swayosd-client --playerctl=play-pause
                play_sound
                ;;
            next)
                swayosd-client --playerctl=next
                play_sound
                ;;
            prev)
                swayosd-client --playerctl=prev
                play_sound
                ;;
            *)
                echo "unknown media action: $action" >&2
                exit 1
            ;;
        esac
        ;;
    *)
        echo "unknown command: $cmd" >&2
        exit 1
        ;;
esac
