#!/usr/bin/env bash
set -euo pipefail

FILE="/etc/nixos/custom-apps/app-hyprcapture.nix"
DRY_RUN=false

usage() {
    echo "Usage: $0 [--dry-run] [FILE]"
    echo
    echo "  --dry-run    Show changes without modifying the file"
    echo "  --help       Show this help"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            FILE="$1"
            shift
            ;;
    esac
done

if [[ ! -f "$FILE" ]]; then
    echo "Error: File not found: $FILE" >&2
    exit 1
fi

echo "-> Fetching latest commit for HyprCapture via git ls-remote..."

REPO_URL="https://github.com/gfhdhytghd/HyprCapture"

# Get the latest commit hash directly from remote HEAD
LATEST_REV="$(git ls-remote "$REPO_URL" HEAD | awk '{print $1}')"

if [[ -z "$LATEST_REV" ]]; then
    echo "Error: Could not fetch latest commit from repository." >&2
    exit 1
fi

SHORT_REV="${LATEST_REV:0:7}"
echo "-> Latest commit found: $SHORT_REV ($LATEST_REV)"

# ------------------------------------------------------------
# Prefetch the tarball hash using Nix
# ------------------------------------------------------------
TARBALL_URL="$REPO_URL/archive/$LATEST_REV.tar.gz"

echo "-> Calculating Nix hash for tarball (this may take a moment)..."
# nrx-prefetch-url outputs base32 hash by default when given --print-path or standard output
SRI_HASH="$(nix-prefetch-url --type sha256 --unpack "$TARBALL_URL" 2>/dev/null | tail -n 1 | xargs -I {} nix hash convert --hash-algo sha256 --to sri {})"

echo "-> New hash: $SRI_HASH"

# ------------------------------------------------------------
# Create temporary copy and SED substitution
# ------------------------------------------------------------
TMP_FILE="$(mktemp)"
SED_FILE="$(mktemp)"

trap 'rm -f "$TMP_FILE" "$SED_FILE"' EXIT

cp "$FILE" "$TMP_FILE"

cat > "$SED_FILE" <<EOF
s|^\([[:space:]]*rev[[:space:]]*=[[:space:]]*"\)[^"]*\(";.*\)$|\1${SHORT_REV}\2|
s|^\([[:space:]]*hash[[:space:]]*=[[:space:]]*"\)[^"]*\(";.*\)$|\1${SRI_HASH}\2|
s|^\([[:space:]]*sha256[[:space:]]*=[[:space:]]*"\)[^"]*\(";.*\)$|\1${SRI_HASH}\2|
EOF

sed -i -f "$SED_FILE" "$TMP_FILE"

# ------------------------------------------------------------
# Diff and output
# ------------------------------------------------------------
echo
echo "==================== DIFF ===================="

if diff -u "$FILE" "$TMP_FILE"; then
    echo "No changes required (already up to date)."
    exit 0
fi

echo "==============================================="

if [[ "$DRY_RUN" == true ]]; then
    echo
    echo "DRY RUN: no files were modified."
    exit 0
fi

# ------------------------------------------------------------
# Apply
# ------------------------------------------------------------
BACKUP="${FILE}.bak"

cp "$FILE" "$BACKUP"
cp "$TMP_FILE" "$FILE"

echo
echo "Successfully updated:"
echo "  $FILE"
echo "Backup saved to:"
echo "  $BACKUP"
