#!/usr/bin/env bash
set -euo pipefail

# Start GNOME Keyring with secrets and SSH support, then launch Hyprland.
# This ensures the session gets the proper SSH_AUTH_SOCK and GNOME_KEYRING_CONTROL env.
eval "$(/run/current-system/sw/bin/gnome-keyring-daemon --start --components=secrets,ssh)"

if [ -n "${SSH_AUTH_SOCK:-}" ]; then
  export SSH_AUTH_SOCK
fi
if [ -n "${GNOME_KEYRING_CONTROL:-}" ]; then
  export GNOME_KEYRING_CONTROL
fi

exec /run/current-system/sw/bin/start-hyprland
