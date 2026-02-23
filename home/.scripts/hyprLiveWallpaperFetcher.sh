#!/usr/bin/env bash

set -euo pipefail

WALLPAPER_DIR="$HOME/.wallpapers"
mkdir -p "$WALLPAPER_DIR"

WALLPAPERS=(
    "girl-behind-curtains.mp4|https://motionbgs.com/dl/4k/8925"
    "purple-lavender.mp4|https://www.youtube.com/watch?v=oK6_bbHaxCM"
    "moonlight.mp4|https://www.youtube.com/watch?v=IcdoqKwMzo0"
    "purple-fuji.mp4|https://www.youtube.com/watch?v=AvAqDvsHtQE"
    "anime-purple-evening-sky.mp4|https://www.youtube.com/watch?v=JoH6rqdQU8A"
    "dragon-solo-level-up.mp4|https://www.youtube.com/watch?v=zVtMJBR-Clo"
    "interstellar-gargantua.mp4|https://www.youtube.com/watch?v=gU4vSEZwiyE"
    "futuristic-neon-delorean.mp4|https://www.youtube.com/watch?v=hcVT8Th6JVM"
    "kaneki-ken-kakuja.mp4|https://www.youtube.com/watch?v=2LDGFpL8s98"
    "ken-kaneki-tokyo-ghoul.mp4|https://www.youtube.com/watch?v=MY8jo2Qswr4"
    "red-forestr-torii.mp4|https://www.youtube.com/watch?v=_kIFYrhlekA"
    "live-wallpaper-anime.mp4|https://www.youtube.com/watch?v=fKcF32dmcDk"
    "girl-behind-curtains-revamped.mp4|https://www.youtube.com/watch?v=zKaLDs62TFQ"
    "cat-in-the-swamp.mp4|https://www.youtube.com/watch?v=ZXHY-EnWPGw"
)

echo "Starting ULTRA quality wallpaper download..."

for item in "${WALLPAPERS[@]}"; do
    IFS="|" read -r name ref <<< "$item"

    OUTPUT="$WALLPAPER_DIR/$name"

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