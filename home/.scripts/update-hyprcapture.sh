#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# HyprCapture Nix package updater
#
# Tracks the latest GitHub RELEASE TAG.
#
# Repository:
#   https://github.com/gfhdhytghd/HyprCapture
#
# Example tags:
#   v0.2.7-0.56.1
#   v0.2.6-0.56.0
#
# Usage:
#   update-hyprcapture.sh
#   update-hyprcapture.sh --dry-run
#   update-hyprcapture.sh /path/to/app-hyprcapture.nix
# ---------------------------------------------------------------------------

FILE="/etc/nixos/custom-apps/app-hyprcapture.nix"
DRY_RUN=false

REPO_URL="https://github.com/gfhdhytghd/HyprCapture"

usage() {
    echo "Usage: $0 [--dry-run] [FILE]"
    echo
    echo "Update app-hyprcapture.nix to the latest GitHub release."
    echo
    echo "Options:"
    echo "  --dry-run    Show changes without modifying the file"
    echo "  --help       Show this help"
    echo
    echo "Arguments:"
    echo "  FILE         Nix package file to update"
    echo "               Default: $FILE"
}

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

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
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;

        *)
            FILE="$1"
            shift
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

if [[ ! -f "$FILE" ]]; then
    echo "Error: File not found: $FILE" >&2
    exit 1
fi

for cmd in git nix nix-prefetch-url awk sed diff mktemp cp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command not found: $cmd" >&2
        exit 1
    fi
done

# ---------------------------------------------------------------------------
# Fetch latest RELEASE TAG
# ---------------------------------------------------------------------------

echo "-> Fetching latest release for HyprCapture..."
echo "   Repository: $REPO_URL"

LATEST_TAG="$(
    git ls-remote --tags --refs "$REPO_URL" |
        awk -F/ '
            $NF ~ /^v[0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.[0-9]+\.[0-9]+$/ {
                print $NF
            }
        ' |
        sort -V |
        tail -n 1
)"

if [[ -z "$LATEST_TAG" ]]; then
    echo "Error: Could not determine latest release tag." >&2
    exit 1
fi

VERSION="${LATEST_TAG#v}"

echo "-> Latest release:"
echo "   Tag:     $LATEST_TAG"
echo "   Version: $VERSION"

# ---------------------------------------------------------------------------
# Calculate source hash
# ---------------------------------------------------------------------------

TARBALL_URL="$REPO_URL/archive/refs/tags/$LATEST_TAG.tar.gz"

echo
echo "-> Calculating Nix source hash..."
echo "   URL: $TARBALL_URL"
echo "   This may take a moment."

BASE32_HASH="$(
    nix-prefetch-url \
        --type sha256 \
        --unpack \
        "$TARBALL_URL" |
        tail -n 1
)"

if [[ -z "$BASE32_HASH" ]]; then
    echo "Error: Could not calculate source hash." >&2
    exit 1
fi

SRI_HASH="$(
    nix hash convert \
        --hash-algo sha256 \
        --to sri \
        "$BASE32_HASH"
)"

if [[ -z "$SRI_HASH" ]]; then
    echo "Error: Could not convert hash to SRI format." >&2
    exit 1
fi

echo "-> New source hash:"
echo "   $SRI_HASH"

# ---------------------------------------------------------------------------
# Read current values
# ---------------------------------------------------------------------------

echo
echo "-> Current package:"

CURRENT_VERSION="$(
    awk '
        /^[[:space:]]*version[[:space:]]*=/ {
            line = $0
            sub(/^[[:space:]]*version[[:space:]]*=[[:space:]]*"/, "", line)
            sub(/".*$/, "", line)
            print line
            exit
        }
    ' "$FILE"
)"

CURRENT_REV="$(
    awk '
        /pkgs\.fetchFromGitHub[[:space:]]*\{/ {
            in_github = 1
        }

        in_github && /^[[:space:]]*rev[[:space:]]*=/ {
            line = $0
            sub(/^[[:space:]]*rev[[:space:]]*=[[:space:]]*"/, "", line)
            sub(/".*$/, "", line)
            print line
            exit
        }

        in_github && /^[[:space:]]*};[[:space:]]*$/ {
            in_github = 0
        }
    ' "$FILE"
)"

CURRENT_HASH="$(
    awk '
        /pkgs\.fetchFromGitHub[[:space:]]*\{/ {
            in_github = 1
        }

        in_github && (/^[[:space:]]*hash[[:space:]]*=/ || /^[[:space:]]*sha256[[:space:]]*=/) {
            line = $0
            sub(/^[[:space:]]*(hash|sha256)[[:space:]]*=[[:space:]]*"/, "", line)
            sub(/".*$/, "", line)
            print line
            exit
        }

        in_github && /^[[:space:]]*};[[:space:]]*$/ {
            in_github = 0
        }
    ' "$FILE"
)"

echo "   version: ${CURRENT_VERSION:-<not found>}"
echo "   rev:     ${CURRENT_REV:-<not found>}"
echo "   hash:    ${CURRENT_HASH:-<not found>}"

# ---------------------------------------------------------------------------
# Create temporary file
# ---------------------------------------------------------------------------

TMP_FILE="$(mktemp)"

cleanup() {
    rm -f "$TMP_FILE"
}

trap cleanup EXIT

cp "$FILE" "$TMP_FILE"

# ---------------------------------------------------------------------------
# Update package
# ---------------------------------------------------------------------------

awk \
    -v new_version="$VERSION" \
    -v new_tag="$LATEST_TAG" \
    -v new_hash="$SRI_HASH" '
BEGIN {
    in_github = 0
    found_version = 0
    found_github = 0
    found_rev = 0
    found_hash = 0
}

{
    line = $0

    if (!found_version &&
        line ~ /^[[:space:]]*version[[:space:]]*=/) {

        match(line, /^[[:space:]]*/)
        indent = substr(line, RSTART, RLENGTH)

        print indent "version = \"" new_version "\";"
        found_version = 1
        next
    }

    if (line ~ /pkgs\.fetchFromGitHub[[:space:]]*\{/) {
        in_github = 1
        found_github = 1
    }

    if (in_github) {

        if (line ~ /^[[:space:]]*rev[[:space:]]*=/) {
            match(line, /^[[:space:]]*/)
            indent = substr(line, RSTART, RLENGTH)

            print indent "rev = \"" new_tag "\";"
            found_rev = 1
            next
        }

        if (line ~ /^[[:space:]]*hash[[:space:]]*=/ || line ~ /^[[:space:]]*sha256[[:space:]]*=/) {
            match(line, /^[[:space:]]*/)
            indent = substr(line, RSTART, RLENGTH)

            # Isolate the exact key name (hash or sha256) cleanly
            key = line
            sub(/^[[:space:]]*/, "", key)
            sub(/[[:space:]]*=.*$/, "", key)

            print indent key " = \"" new_hash "\";"
            found_hash = 1
            next
        }

        if (line ~ /^[[:space:]]*};[[:space:]]*$/) {
            in_github = 0
        }
    }

    print line
}

END {
    if (!found_version) exit 2
    if (!found_github) exit 3
    if (!found_rev) exit 4
    if (!found_hash) exit 5
}
' "$FILE" > "$TMP_FILE"

# ---------------------------------------------------------------------------
# Validate generated file
# ---------------------------------------------------------------------------

UPDATED_VERSION="$(
    awk '
        /^[[:space:]]*version[[:space:]]*=/ {
            line = $0
            sub(/^[[:space:]]*version[[:space:]]*=[[:space:]]*"/, "", line)
            sub(/".*$/, "", line)
            print line
            exit
        }
    ' "$TMP_FILE"
)"

UPDATED_REV="$(
    awk '
        /pkgs\.fetchFromGitHub[[:space:]]*\{/ {
            in_github = 1
        }

        in_github && /^[[:space:]]*rev[[:space:]]*=/ {
            line = $0
            sub(/^[[:space:]]*rev[[:space:]]*=[[:space:]]*"/, "", line)
            sub(/".*$/, "", line)
            print line
            exit
        }
    ' "$TMP_FILE"
)"

if [[ "$UPDATED_VERSION" != "$VERSION" ]]; then
    echo "Error: Failed to update version." >&2
    exit 1
fi

if [[ "$UPDATED_REV" != "$LATEST_TAG" ]]; then
    echo "Error: Failed to update rev." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Show diff & apply
# ---------------------------------------------------------------------------

echo
echo "==================== DIFF ===================="

if diff -u "$FILE" "$TMP_FILE"; then
    echo
    echo "No changes required."
    echo "app-hyprcapture.nix is already up to date."
    exit 0
fi

echo "==============================================="

if [[ "$DRY_RUN" == true ]]; then
    echo
    echo "DRY RUN: no files were modified."
    exit 0
fi

BACKUP="${FILE}.bak"
cp "$FILE" "$BACKUP"
cp "$TMP_FILE" "$FILE"

echo
echo "Successfully updated:"
echo "  $FILE"
echo
echo "Release tag: $LATEST_TAG"
echo "Version:     $VERSION"
echo "Backup:      $BACKUP"