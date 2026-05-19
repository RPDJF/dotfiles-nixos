#!/usr/bin/env bash

set -euo pipefail

WALLPAPER_DIR="$HOME/.wallpapers"
mkdir -p "$WALLPAPER_DIR"

TEST_MODE=false

if [[ "${1:-}" == "--test" ]]; then
    TEST_MODE=true
    echo "Running in TEST MODE (no downloads)"
fi

WALLPAPERS=(
    "Lost in Space's Embrace.mp4|https://motionbgs.com/dl/4k/7013"
    "Anime Girl Loading System.mp4|https://motionbgs.com/dl/4k/6004"
    "Kaneki Ken Black Angel Of Death Laying.mp4|https://motionbgs.com/dl/4k/4513"
    "Frieren the Slayer.mp4|https://motionbgs.com/dl/4k/6768"
    "Deltarune.mp4|https://motionbgs.com/dl/4k/8061"
)

echo "Processing wallpapers..."

for item in "${WALLPAPERS[@]}"; do
    IFS="|" read -r name ref <<< "$item"

    OUTPUT="$WALLPAPER_DIR/$name"

    if $TEST_MODE; then
        echo -n "Testing $name ... "

        if yt-dlp --simulate --skip-download --no-playlist "$ref" >/dev/null 2>&1; then
            echo "OK"
        else
            echo "FAILED"
        fi

        continue
    fi

    if [[ -f "$OUTPUT" ]]; then
        echo "Skipping $name: already exists."
        continue
    fi

    echo "Downloading BEST available video + audio: $name"

    yt-dlp \
        --no-playlist \
        --merge-output-format mp4 \
        -f "bestvideo*+bestaudio/best" \
        -o "$OUTPUT" \
        "$ref"

    echo "Saved $name"
done

echo "All wallpapers downloaded to $WALLPAPER_DIR"