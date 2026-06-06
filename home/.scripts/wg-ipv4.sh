#!/usr/bin/env bash

set -e

ACTION="$1"
CONF="$2"

usage() {
    echo "Usage:"
    echo "  wg-ipv4.sh up ~/wireguard/wg0.conf"
    echo "  wg-ipv4.sh down ~/wireguard/wg0.conf"
    exit 1
}

[ -z "$ACTION" ] && usage
[ -z "$CONF" ] && usage

STATE_DIR="$HOME/.cache/wg-waybar"
mkdir -p "$STATE_DIR"

CONF_NAME=$(basename "$CONF" .conf)

STATUS_FILE="$STATE_DIR/$CONF_NAME.status"
BADGE_FILE="$STATE_DIR/$CONF_NAME.badge"

TMP_CONF="/tmp/${CONF_NAME}.conf"

# init
[ -f "$STATUS_FILE" ] || echo "down" > "$STATUS_FILE"
[ -f "$BADGE_FILE" ] || echo "on" > "$BADGE_FILE"

vpn_set_up() {
    echo "up" > "$STATUS_FILE"
}

vpn_set_down() {
    echo "down" > "$STATUS_FILE"
}

resolve_ipv4() {
    ENDPOINT=$(grep -E '^Endpoint' "$CONF" | awk '{print $3}')

    HOST=$(echo "$ENDPOINT" | cut -d: -f1)
    PORT=$(echo "$ENDPOINT" | rev | cut -d: -f1 | rev)

    echo "[+] Resolving IPv4 for $HOST ..."

    IPV4=$(getent ahostsv4 "$HOST" | awk '{print $1}' | head -n1)

    if [ -z "$IPV4" ]; then
        echo "[-] No IPv4 found"
        exit 1
    fi

    echo "[+] IPv4 = $IPV4"

    sed "s|Endpoint = .*|Endpoint = $IPV4:$PORT|" "$CONF" > "$TMP_CONF"
}

vpn_up() {
    resolve_ipv4

    echo "[+] Bringing interface up..."

    sudo wg-quick up "$TMP_CONF"

    vpn_set_up

    notify-send "VPN" "$CONF_NAME connected"
}

vpn_down() {
    if [ ! -f "$TMP_CONF" ]; then
        echo "[-] Temp config not found: $TMP_CONF"
        exit 1
    fi

    echo "[+] Bringing interface down..."

    sudo wg-quick down "$TMP_CONF"

    rm -f "$TMP_CONF"

    vpn_set_down

    notify-send "VPN" "$CONF_NAME disconnected"
}

case "$ACTION" in
    up)
        vpn_up
        ;;
    down)
        vpn_down
        ;;
    *)
        usage
        ;;
esac