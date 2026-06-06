#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/hypr/hyprland.profiles.d/current/monitors.conf"
TEMP_FILE=$(mktemp)

RED='\033[0;31m'
NC='\033[0m'

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file not found at $CONFIG_FILE${NC}" >&2
    exit 1
fi

trap 'rm -f "$TEMP_FILE"' EXIT

if ! grep -q "^# SDR" "$CONFIG_FILE" || ! grep -q "^# HDR" "$CONFIG_FILE"; then
    echo -e "${RED}Error: Missing '# SDR' or '# HDR' markers in your config file!${NC}" >&2
    echo -e "${RED}Please make sure your config looks exactly like this:${NC}\n"
    
    echo -e "  # SDR"
    echo -e "  monitor=desc:ASUSTek..., 3840x2160..."
    echo -e "  # HDR"
    echo -e "  #monitor=desc:ASUSTek..., 3840x2160...\n"
    exit 1
fi

enable_hdr() {
    echo "Switching to HDR..."
    
    cp "$CONFIG_FILE" "$TEMP_FILE"
    
    sed -i '/^# SDR/ { n; s/^[[:space:]]*\([^#]\)/#\1/ }' "$TEMP_FILE"
    sed -i '/^# HDR/ { n; s/^[[:space:]]*#[[:space:]]*// }' "$TEMP_FILE"
    
    mv "$TEMP_FILE" "$CONFIG_FILE"
}

enable_sdr() {
    echo "Switching to SDR..."
    
    cp "$CONFIG_FILE" "$TEMP_FILE"
    
    sed -i '/^# HDR/ { n; s/^[[:space:]]*\([^#]\)/#\1/ }' "$TEMP_FILE"
    sed -i '/^# SDR/ { n; s/^[[:space:]]*#[[:space:]]*// }' "$TEMP_FILE"
    
    mv "$TEMP_FILE" "$CONFIG_FILE"
}

is_hdr_active() {
    grep -A1 "^# HDR" "$CONFIG_FILE" | tail -n1 | grep -q "^[^#]"
}

case "${1,,}" in
    on|hdr)
        enable_hdr
        ;;
    off|sdr)
        enable_sdr
        ;;
    toggle|"")
        if is_hdr_active; then
            enable_sdr
        else
            enable_hdr
        fi
        ;;
    *)
        echo "Usage: $(basename "$0") [on|off|toggle]"
        exit 1
        ;;
esac

echo "Done!"