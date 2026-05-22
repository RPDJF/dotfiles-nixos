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

# Detect largest monitor width
get_max_resolution() {
    hyprctl monitors 2>/dev/null | awk '
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

# Detect best encoder
detect_encoder() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "nvenc"
        return
    fi

    if lspci | grep -qi "amd"; then
        echo "vaapi"
        return
    fi

    if lspci | grep -qi "intel"; then
        echo "qsv"
        return
    fi

    echo "x264"
}

ENCODER=$(detect_encoder)
MAX_W=$(get_max_resolution)

echo "Detected encoder: $ENCODER"
echo "Detected max monitor width: ${MAX_W}px"

BASE_FILTER="scale='min(iw,${MAX_W})':-2:flags=lanczos,fps=30"

case "$ENCODER" in
    nvenc)
        VIDEO_FILTER="${BASE_FILTER},format=yuv420p"
        ENCODER_OPTS="-c:v h264_nvenc -preset p5 -cq 20"
        ;;

    vaapi)
        VIDEO_FILTER="${BASE_FILTER},format=nv12,hwupload"
        ENCODER_OPTS="-vaapi_device /dev/dri/renderD128 -c:v h264_vaapi -qp 20"
        ;;

    qsv)
        VIDEO_FILTER="${BASE_FILTER},format=nv12"
        ENCODER_OPTS="-c:v h264_qsv -global_quality 20"
        ;;

    *)
        VIDEO_FILTER="${BASE_FILTER},format=yuv420p"
        ENCODER_OPTS="-c:v libx264 -preset slow -crf 20 -tune film -profile:v high -level 4.1"
        ;;
esac

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

    # SKIP IF ALREADY OPTIMIZED
    if [[ -f "$OPTIMIZED_OUTPUT" ]]; then
        echo "Skipping optimization (exists): $name"
        continue
    fi

    echo "Optimizing: $name using $ENCODER"

    TMP_OUTPUT="${OPTIMIZED_OUTPUT}.tmp.mp4"

    if ffmpeg -y \
        -i "$ORIGINAL_OUTPUT" \
        -vf "$VIDEO_FILTER" \
        $ENCODER_OPTS \
        -movflags +faststart \
        -an \
        "$TMP_OUTPUT"; then

        # Verify file is valid
        if ffprobe "$TMP_OUTPUT" >/dev/null 2>&1; then
            mv "$TMP_OUTPUT" "$OPTIMIZED_OUTPUT"
            echo "Optimized: $name"
        else
            echo "Invalid output file: $name"
            rm -f "$TMP_OUTPUT"
        fi

    else
        echo "FFmpeg failed: $name"
        rm -f "$TMP_OUTPUT"
    fi
done

echo
echo "All wallpapers processed."
echo "Originals:  $ORIGINAL_DIR"
echo "Optimized:  $OPTIMIZED_DIR"
echo "Encoder used: $ENCODER"