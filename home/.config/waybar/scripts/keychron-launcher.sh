#!/usr/bin/env bash

URL="https://launcher.keychron.com"

# Try native browsers first
for browser in google-chrome chromium opera microsoft-edge-stable edge; do
    if command -v "$browser" >/dev/null 2>&1; then
        exec "$browser" "$URL"
    fi
done

# Fallback: open inside a temporary nix-shell with chromium (with unfree allowed)
exec nix-shell -p chromium --run "NIXPKGS_ALLOW_UNFREE=1 chromium --enable-features=WebUSB $URL"
