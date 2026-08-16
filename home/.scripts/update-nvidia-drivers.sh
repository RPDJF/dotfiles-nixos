#!/usr/bin/env bash
set -euo pipefail

FILE="/etc/nixos/profiles/ws-nixosx3d/hardware-configuration.nix"
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
    echo "File not found: $FILE" >&2
    exit 1
fi

# ------------------------------------------------------------
# Get the actual nixpkgs checkout used by the nixpkgs flake
# ------------------------------------------------------------

NIXPKGS_PATH="$(
    nix eval \
        --impure \
        --raw \
        --expr '(builtins.getFlake "nixpkgs").outPath'
)"

NVIDIA_FILE="$NIXPKGS_PATH/pkgs/os-specific/linux/nvidia-x11/default.nix"

if [[ ! -f "$NVIDIA_FILE" ]]; then
    echo "Could not find:"
    echo "$NVIDIA_FILE"
    exit 1
fi

echo "Using nixpkgs:"
echo "  $NIXPKGS_PATH"

# ------------------------------------------------------------
# Extract bleeding_edge from the nixpkgs source.
#
# bleeding_edge = selectHighestVersion latest beta;
#
# At the moment this resolves to new_feature 610.57.04.
# ------------------------------------------------------------

NEW_FEATURE_BLOCK="$(
    awk '
        /^[[:space:]]*new_feature[[:space:]]*=[[:space:]]*generic[[:space:]]*\{/ {
            found=1
        }

        found {
            print
        }

        found && /^[[:space:]]*};[[:space:]]*$/ {
            exit
        }
    ' "$NVIDIA_FILE"
)"

BETA_BLOCK="$(
    awk '
        /^[[:space:]]*beta[[:space:]]*=[[:space:]]*generic[[:space:]]*\{/ {
            found=1
        }

        found {
            print
        }

        found && /^[[:space:]]*};[[:space:]]*$/ {
            exit
        }
    ' "$NVIDIA_FILE"
)"

get_version() {
    printf '%s\n' "$1" |
        sed -nE 's/^[[:space:]]*version[[:space:]]*=[[:space:]]*"([^"]+)";/\1/p' |
        head -n1
}

NEW_FEATURE_VERSION="$(get_version "$NEW_FEATURE_BLOCK")"
BETA_VERSION="$(get_version "$BETA_BLOCK")"

# ------------------------------------------------------------
# Compare versions using Nix itself.
# This avoids implementing Nix version comparison in Bash.
# ------------------------------------------------------------

BLEEDING_BLOCK="$NEW_FEATURE_BLOCK"

if nix eval --impure --expr \
    "let lib = (import (builtins.getFlake \"nixpkgs\").outPath {}).lib;
     in lib.versionOlder \"$NEW_FEATURE_VERSION\" \"$BETA_VERSION\"" \
    | grep -q true; then

    BLEEDING_BLOCK="$BETA_BLOCK"
fi

VERSION="$(get_version "$BLEEDING_BLOCK")"

get_hash() {
    local name="$1"

    printf '%s\n' "$BLEEDING_BLOCK" |
        sed -nE \
            "s/^[[:space:]]*${name}[[:space:]]*=[[:space:]]*\"([^\"]+)\";.*/\1/p" |
        head -n1
}

SHA256_64BIT="$(get_hash sha256_64bit)"
OPEN_SHA256="$(get_hash openSha256)"
SETTINGS_SHA256="$(get_hash settingsSha256)"
PERSISTENCED_SHA256="$(get_hash persistencedSha256)"

echo
echo "Bleeding-edge NVIDIA:"
echo "  version:            $VERSION"
echo "  sha256_64bit:       $SHA256_64BIT"
echo "  openSha256:         $OPEN_SHA256"
echo "  settingsSha256:     $SETTINGS_SHA256"

if [[ "$PERSISTENCED_SHA256" == *fakeHash* || -z "$PERSISTENCED_SHA256" ]]; then
    echo "  persistencedSha256: fakeHash (unchanged)"
else
    echo "  persistencedSha256: $PERSISTENCED_SHA256"
fi

# ------------------------------------------------------------
# Create temporary copy
# ------------------------------------------------------------

TMP_FILE="$(mktemp)"
SED_FILE="$(mktemp)"

trap 'rm -f "$TMP_FILE" "$SED_FILE"' EXIT

cp "$FILE" "$TMP_FILE"

# ------------------------------------------------------------
# Find mkDriver block
# ------------------------------------------------------------

START_LINE="$(
    grep -n \
        'package = config.boot.kernelPackages.nvidiaPackages.mkDriver {' \
        "$TMP_FILE" |
        head -n1 |
        cut -d: -f1
)"

if [[ -z "$START_LINE" ]]; then
    echo
    echo "Could not find NVIDIA mkDriver block in:"
    echo "$FILE"
    exit 1
fi

END_OFFSET="$(
    tail -n +"$START_LINE" "$TMP_FILE" |
        grep -n -m1 '^[[:space:]]*};[[:space:]]*$' |
        cut -d: -f1
)"

if [[ -z "$END_OFFSET" ]]; then
    echo "Could not find end of NVIDIA mkDriver block." >&2
    exit 1
fi

END_LINE=$((START_LINE + END_OFFSET - 1))

echo
echo "Updating lines $START_LINE-$END_LINE"

# ------------------------------------------------------------
# Generate sed script
# ------------------------------------------------------------

cat > "$SED_FILE" <<EOF
${START_LINE},${END_LINE}s|^\([[:space:]]*version[[:space:]]*=[[:space:]]*"\)[^"]*\(";.*\)$|\1${VERSION}\2|
${START_LINE},${END_LINE}s|^\([[:space:]]*sha256_64bit[[:space:]]*=[[:space:]]*"\)[^"]*\(";.*\)$|\1${SHA256_64BIT}\2|
${START_LINE},${END_LINE}s|^\([[:space:]]*openSha256[[:space:]]*=[[:space:]]*"\)[^"]*\(";.*\)$|\1${OPEN_SHA256}\2|
${START_LINE},${END_LINE}s|^\([[:space:]]*settingsSha256[[:space:]]*=[[:space:]]*"\)[^"]*\(";.*\)$|\1${SETTINGS_SHA256}\2|
EOF

# Don't modify fakeHash values.
if [[ -n "$PERSISTENCED_SHA256" &&
      "$PERSISTENCED_SHA256" != *fakeHash* ]]; then

    cat >> "$SED_FILE" <<EOF
${START_LINE},${END_LINE}s|^\([[:space:]]*persistencedSha256[[:space:]]*=[[:space:]]*"\)[^"]*\(";.*\)$|\1${PERSISTENCED_SHA256}\2|
EOF
fi

sed -i -f "$SED_FILE" "$TMP_FILE"

# ------------------------------------------------------------
# Diff
# ------------------------------------------------------------

echo
echo "==================== DIFF ===================="

if diff -u "$FILE" "$TMP_FILE"; then
    echo "No changes required."
fi

echo "==============================================="

# ------------------------------------------------------------
# Dry run
# ------------------------------------------------------------

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
echo "Updated:"
echo "  $FILE"

echo
echo "Backup:"
echo "  $BACKUP"
