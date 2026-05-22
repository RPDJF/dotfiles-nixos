#!/usr/bin/env bash

set -e

CONF="$1"

if [ -z "$CONF" ]; then
  echo "Usage: $0 wg0.conf"
  exit 1
fi

# extract endpoint host:port
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

TMP="/tmp/wg-ipv4.conf"

echo "[+] Generating temp config: $TMP"

cat "$CONF" | sed "s|Endpoint = .*|Endpoint = $IPV4:$PORT|" > "$TMP"

echo "[+] Bringing interface up..."

sudo wg-quick up "$TMP"
