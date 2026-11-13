#!/usr/bin/env bash
set -euo pipefail

FILE="/etc/nixos/custom-apps/app-serein-discord.nix"
DRY_RUN=false
REPO_URL="https://github.com/ViceVerse-cz/Serein"

usage() {
    echo "Usage: $0 [--dry-run] [FILE]"
    echo
    echo "Update app-serein-discord.nix to the latest Serein version tag."
    echo
    echo "Options:"
    echo "  --dry-run    Show changes without modifying the Nix file"
    echo "  --help       Show this help"
    echo
    echo "Arguments:"
    echo "  FILE         Nix package file to update"
    echo "               Default: $FILE"
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
        -* )
            echo "Error: Unknown option: $1" >&2
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

for command in git nix nix-prefetch-url awk diff mktemp cp; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: Required command not found: $command" >&2
        exit 1
    fi
done

echo "-> Fetching latest Serein version tag..."
echo "   Repository: $REPO_URL"

LATEST_TAG="$(
    git ls-remote --tags --refs "$REPO_URL" |
        awk -F/ '$NF ~ /^v[0-9]+(\.[0-9]+)*([-.][0-9A-Za-z.-]+)?$/ { print $NF }' |
        sort -V |
        tail -n 1
)"

if [[ -z "$LATEST_TAG" ]]; then
    echo "Error: Could not determine the latest Serein version tag." >&2
    exit 1
fi

VERSION="${LATEST_TAG#v}"
TARBALL_URL="$REPO_URL/archive/refs/tags/$LATEST_TAG.tar.gz"

echo "-> Latest Serein tag: $LATEST_TAG"
echo "-> Package version:   $VERSION"
echo "-> Calculating source hash..."

BASE32_HASH="$(
    nix-prefetch-url --type sha256 --unpack "$TARBALL_URL" |
        tail -n 1
)"

if [[ -z "$BASE32_HASH" ]]; then
    echo "Error: Could not calculate the source hash." >&2
    exit 1
fi

SRI_HASH="$(nix hash convert --hash-algo sha256 --to sri "$BASE32_HASH")"
if [[ -z "$SRI_HASH" ]]; then
    echo "Error: Could not convert the source hash to SRI format." >&2
    exit 1
fi

TMP_FILE="$(mktemp)"
cleanup() {
    rm -f "$TMP_FILE"
}
trap cleanup EXIT

awk \
    -v new_version="$VERSION" \
    -v new_tag="$LATEST_TAG" \
    -v new_hash="$SRI_HASH" '
BEGIN {
    in_github = 0
    found_version = 0
    found_rev = 0
    found_hash = 0
}
{
    line = $0

    if (!found_version && line ~ /^[[:space:]]*version[[:space:]]*=/) {
        match(line, /^[[:space:]]*/)
        print substr(line, RSTART, RLENGTH) "version = \"" new_version "\";"
        found_version = 1
        next
    }

    if (line ~ /pkgs\.fetchFromGitHub[[:space:]]*\{/) in_github = 1

    if (in_github && line ~ /^[[:space:]]*rev[[:space:]]*=/) {
        match(line, /^[[:space:]]*/)
        print substr(line, RSTART, RLENGTH) "rev = \"" new_tag "\";"
        found_rev = 1
        next
    }

    if (in_github && (line ~ /^[[:space:]]*hash[[:space:]]*=/ || line ~ /^[[:space:]]*sha256[[:space:]]*=/)) {
        match(line, /^[[:space:]]*/)
        indent = substr(line, RSTART, RLENGTH)
        key = line
        sub(/^[[:space:]]*/, "", key)
        sub(/[[:space:]]*=.*$/, "", key)
        print indent key " = \"" new_hash "\";"
        found_hash = 1
        next
    }

    if (in_github && line ~ /^[[:space:]]*};[[:space:]]*$/) in_github = 0
    print line
}
END {
    if (!found_version || !found_rev || !found_hash) exit 1
}
' "$FILE" > "$TMP_FILE"

UPDATED_VERSION="$(awk -F'"' '/^[[:space:]]*version[[:space:]]*=/ { print $2; exit }' "$TMP_FILE")"
UPDATED_REV="$(awk -F'"' '/^[[:space:]]*rev[[:space:]]*=/ { print $2; exit }' "$TMP_FILE")"
UPDATED_HASH="$(awk -F'"' '/^[[:space:]]*(hash|sha256)[[:space:]]*=/ { print $2; exit }' "$TMP_FILE")"

if [[ "$UPDATED_VERSION" != "$VERSION" || "$UPDATED_REV" != "$LATEST_TAG" || "$UPDATED_HASH" != "$SRI_HASH" ]]; then
    echo "Error: Generated package fields failed validation." >&2
    exit 1
fi

echo "-> New source hash: $SRI_HASH"
echo

if diff -u "$FILE" "$TMP_FILE"; then
    echo "Package is already up to date."
    exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN: no files were modified."
    exit 0
fi

cp "$FILE" "${FILE}.bak"
cp "$TMP_FILE" "$FILE"
echo "Updated $FILE to $LATEST_TAG (backup: ${FILE}.bak)"