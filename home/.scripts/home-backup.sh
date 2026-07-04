#!/usr/bin/env bash
set -euo pipefail

HOST="$(hostname)"
USER_NAME="${USER:-unknown_user}"
DATE="$(date +%Y-%m-%d_%H-%M-%S)"
DEST_DIR="/mnt/shares/backups/hosts/${HOST}"
DEST_FILE="${DEST_DIR}/${DATE}_${USER_NAME}_backup.tar.gz"

CORES=$(nproc)
THREADS=$(( CORES > 1 ? CORES - 1 : 1 ))

# Safety: ensure NAS is mounted
mountpoint -q /mnt/shares/backups || {
    echo "ERROR: NAS /mnt/shares/backups is not mounted"
    exit 1
}

mkdir -p "$DEST_DIR"

echo "Starting archival (compression: $THREADS threads)..."

tar -cf - \
    --one-file-system \
    --ignore-failed-read \
    --exclude='.cache' \
    --exclude='.var/app/*/cache' \
    --exclude='.var/app/*/cache-*' \
    --exclude='.var/app/*/Cache' \
    --exclude='.steam' \
    --exclude='.local/share/Steam' \
    --exclude='.local/share/lutris' \
    --exclude='.config/lutris' \
    --exclude='.var/app/com.heroicgameslauncher.hgl' \
    --exclude='.config/Epic' \
    --exclude='.wine' \
    --exclude='.local/state' \
    --exclude='.docker-composers' \
    --exclude='Games' \
    --exclude='Downloads' \
    --exclude='.local/share/Trash' \
    --exclude='node_modules' \
    --exclude='.npm' \
    --exclude='.cargo' \
    --exclude='.rustup' \
    --exclude='.gradle' \
    --exclude='.m2' \
    --exclude='.yarn' \
    --exclude='.pnpm-store' \
    --exclude='.venv' \
    --exclude='venv' \
    --exclude='__pycache__' \
    --exclude='.pytest_cache' \
    --exclude='.tox' \
    --exclude='.config/plex' \
    --exclude='.cache/plex' \
    --exclude='.local/share/jellyfin' \
    --exclude='.cache/jellyfin' \
    --exclude='.config/google-chrome' \
    --exclude='.config/chromium' \
    --exclude='.config/brave' \
    -C "$HOME" . | zstd -T0 > "${DEST_FILE%.gz}.zst"

echo "Backup stored at: ${DEST_FILE%.gz}.zst"

# rotation
find "$DEST_DIR" -maxdepth 1 -type f -name "*_${USER_NAME}_backup.zst" \
    | sort -r \
    | tail -n +11 \
    | xargs -r rm

echo "Backup complete."

# Optional: show size
du -h "${DEST_FILE%.gz}.zst" 2>/dev/null || true