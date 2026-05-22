#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_DIR="$HOME/.wallpapers/originals"
OPTIMIZED_DIR="$HOME/.wallpapers/optimized"

mkdir -p "$ORIGINAL_DIR"
mkdir -p "$OPTIMIZED_DIR"

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

# Safe monitor detection
get_max_resolution() {
    hyprctl monitors | awk '
        match($0, /[0-9]+x[0-9]+/) {
            split(substr($0, RSTART, RLENGTH), r, "x")
            if (r[1] > max) max = r[1]
        }
        END {
            if (max == 0) max = 3840
            print max
        }
    '
}

# GPU detection
detect_encoder() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "nvenc"
        return
    fi

    if lspci | grep -qi "amd"; then
        echo "amf"
        return
    fi

    if lspci | grep -qi "intel"; then
        echo "qsv"
        return
    fi

    echo "x264"
}

ENCODER=$(detect_encoder)

case "$ENCODER" in
    nvenc)
        FFMPEG_OPTS="-c:v h264_nvenc -preset p5 -cq 20"
        ;;
    amf)
        FFMPEG_OPTS="-c:v h264_amf -quality balanced"
        ;;
    qsv)
        FFMPEG_OPTS="-c:v h264_qsv -global_quality 20"
        ;;
    *)
        FFMPEG_OPTS="-c:v libx264 -preset slow -crf 20 -tune film -profile:v high -level 4.1"
        ;;
esac

echo "Detected encoder: $ENCODER"

# IMPORTANT: fallback-safe resolution
MAX_W=$(get_max_resolution)

echo "Detected max monitor width: ${MAX_W}px"

# Main loop
for item in "${WALLPAPERS[@]}"; do
    IFS="|" read -r name ref <<< "$item"

    ORIGINAL_OUTPUT="$ORIGINAL_DIR/$name"
    OPTIMIZED_OUTPUT="$OPTIMIZED_DIR/$name"

    # TEST MODE
    if $TEST_MODE; then
        echo -n "Testing $name ... "
        if yt-dlp --simulate --skip-download --no-playlist "$ref" >/dev/null 2>&1; then
            echo "OK"
        else
            echo "FAILED"
        fi
        continue
    fi

    # DOWNLOAD
    if [[ ! -f "$ORIGINAL_OUTPUT" ]]; then
        echo "Downloading: $name"

        yt-dlp \
            --no-playlist \
            --merge-output-format mp4 \
            -f "best[ext=mp4]/best" \
            -o "$ORIGINAL_OUTPUT" \
            "$ref"

        echo "Downloaded: $name"
    else
        echo "Skipping download (exists): $name"
    fi

    # OPTIMIZE
    if [[ -f "$OPTIMIZED_OUTPUT" ]]; then
        echo "Skipping optimization (exists): $name"
        continue
    fi

    echo "Optimizing: $name using $ENCODER"

    ffmpeg -y \
        -i "$ORIGINAL_OUTPUT" \
        -vf "scale='min(iw,${MAX_W})':-2:flags=lanczos,fps=30,format=yuv420p" \
        $FFMPEG_OPTS \
        -movflags +faststart+frag_keyframe \
        -an \
        "$OPTIMIZED_OUTPUT"

    echo "Optimized: $name"
done

echo
echo "All wallpapers processed."
echo "Originals:  $ORIGINAL_DIR"
echo "Optimized:  $OPTIMIZED_DIR"
echo "Encoder used: $ENCODER"