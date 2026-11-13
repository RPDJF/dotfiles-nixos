#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# bbport & DLSS Nix package updater
#
# Tracks the latest GitHub RELEASE TAG for both bbport and NVIDIA DLSS.
#
# Repositories:
#   - bbport: https://github.com/deadinside28/bloodborne_pc
#   - DLSS:   https://github.com/NVIDIA/DLSS
#
# Usage:
#   update-bbport.sh
#   update-bbport.sh --dry-run
#   update-bbport.sh /path/to/app-bbport.nix
# ---------------------------------------------------------------------------

FILE="/etc/nixos/custom-apps/app-bbport.nix"
DRY_RUN=false

REPO_URL="https://github.com/deadinside28/bloodborne_pc"
DLSS_REPO_API="https://api.github.com/repos/NVIDIA/DLSS/releases/latest"

usage() {
    echo "Usage: $0 [--dry-run] [FILE]"
    echo
    echo "Update app-bbport.nix to the latest GitHub releases for bbport and NVIDIA DLSS."
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

for cmd in git nix awk sed diff mktemp cp jq curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command not found: $cmd" >&2
        exit 1
    fi
done

# ---------------------------------------------------------------------------
# Fetch latest bbport RELEASE TAG
# ---------------------------------------------------------------------------

echo "-> Fetching latest release for bbport..."
echo "   Repository: $REPO_URL"

LATEST_TAG="$(
    git ls-remote --tags --refs "$REPO_URL" |
        awk -F/ '
            $NF ~ /^v?[0-9]+(\.[0-9]+)*(-pre[0-9]+)?$/ {
                print $NF
            }
        ' |
        sort -V |
        tail -n 1
)"

if [[ -z "$LATEST_TAG" ]]; then
    echo "Error: Could not determine latest bbport release tag." >&2
    exit 1
fi

VERSION="${LATEST_TAG#v}"

echo "-> Latest bbport release:"
echo "   Tag:     $LATEST_TAG"
echo "   Version: $VERSION"

# ---------------------------------------------------------------------------
# Fetch latest NVIDIA DLSS RELEASE TAG
# ---------------------------------------------------------------------------

echo
echo "-> Fetching latest release for NVIDIA DLSS..."
DLSS_LATEST_TAG="$(curl -s "$DLSS_REPO_API" | jq -r .tag_name)"

if [[ -z "$DLSS_LATEST_TAG" || "$DLSS_LATEST_TAG" == "null" ]]; then
    echo "Error: Could not fetch latest DLSS release tag from GitHub API." >&2
    exit 1
fi

DLSS_URL="https://github.com/NVIDIA/DLSS/releases/download/$DLSS_LATEST_TAG/ngx_dlss_demo_linux.zip"

echo "-> Latest DLSS release:"
echo "   Tag:     $DLSS_LATEST_TAG"
echo "   URL:     $DLSS_URL"

# ---------------------------------------------------------------------------
# Calculate bbport source hash (including submodules via nix-prefetch-git)
# ---------------------------------------------------------------------------

echo
echo "-> Calculating bbport Nix source hash with submodules..."
echo "   This may take a moment."

PREFETCH_JSON="$(
    nix run nixpkgs#nix-prefetch-git -- \
        --url "$REPO_URL" \
        --rev "$LATEST_TAG" \
        --fetch-submodules \
        --quiet
)"

if [[ -z "$PREFETCH_JSON" ]]; then
    echo "Error: nix-prefetch-git failed to return data." >&2
    exit 1
fi

BASE32_HASH="$(echo "$PREFETCH_JSON" | jq -r '.hash')"

if [[ -z "$BASE32_HASH" || "$BASE32_HASH" == "null" ]]; then
    echo "Error: Could not extract hash from prefetch JSON." >&2
    exit 1
fi

# Ensure SRI format for bbport
if [[ "$BASE32_HASH" != sha256-* ]]; then
    SRI_HASH="$(
        nix hash convert \
            --hash-algo sha256 \
            --to sri \
            "$BASE32_HASH"
    )"
else
    SRI_HASH="$BASE32_HASH"
fi

if [[ -z "$SRI_HASH" ]]; then
    echo "Error: Could not convert bbport hash to SRI format." >&2
    exit 1
fi

echo "-> New bbport source hash:"
echo "   $SRI_HASH"

# ---------------------------------------------------------------------------
# Calculate NVIDIA DLSS SDK hash
# ---------------------------------------------------------------------------

echo
echo "-> Calculating DLSS SDK hash..."
DLSS_PREFETCH_JSON="$(nix store prefetch-file --json "$DLSS_URL")"
DLSS_SRI_HASH="$(echo "$DLSS_PREFETCH_JSON" | jq -r '.hash')"

if [[ -z "$DLSS_SRI_HASH" || "$DLSS_SRI_HASH" == "null" ]]; then
    echo "Error: Could not prefetch DLSS SDK archive." >&2
    exit 1
fi

echo "-> New DLSS SDK hash:"
echo "   $DLSS_SRI_HASH"

# ---------------------------------------------------------------------------
# Read current values from FILE
# ---------------------------------------------------------------------------

echo
echo "-> Current package info read from file..."

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

echo "   version: ${CURRENT_VERSION:-<not found>}"

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
# Update package file (bbport + dlssSdk)
# ---------------------------------------------------------------------------

awk \
    -v new_version="$VERSION" \
    -v new_tag="$LATEST_TAG" \
    -v new_hash="$SRI_HASH" \
    -v new_dlss_url="$DLSS_URL" \
    -v new_dlss_hash="$DLSS_SRI_HASH" '
BEGIN {
    in_github = 0
    in_dlss = 0
    found_version = 0
    found_github = 0
    found_rev = 0
    found_hash = 0
    found_dlss = 0
}

{
    line = $0

    # 1. Update bbport version
    if (!found_version && line ~ /^[[:space:]]*version[[:space:]]*=/) {
        match(line, /^[[:space:]]*/)
        indent = substr(line, RSTART, RLENGTH)
        print indent "version = \"" new_version "\";"
        found_version = 1
        next
    }

    # 2. Track fetchFromGitHub block for bbport
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

        if (line ~ /^[[:space:]]*(hash|sha256)[[:space:]]*=/) {
            match(line, /^[[:space:]]*/)
            indent = substr(line, RSTART, RLENGTH)
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

    # 3. Track dlssSdk = pkgs.fetchurl block
    if (line ~ /dlssSdk[[:space:]]*=[[:space:]]*pkgs\.fetchurl[[:space:]]*\{/) {
        in_dlss = 1
        found_dlss = 1
        print line
        next
    }

    if (in_dlss) {
        if (line ~ /^[[:space:]]*url[[:space:]]*=/) {
            match(line, /^[[:space:]]*/)
            indent = substr(line, RSTART, RLENGTH)
            print indent "url = \"" new_dlss_url "\";"
            next
        }

        if (line ~ /^[[:space:]]*(hash|sha256)[[:space:]]*=/) {
            match(line, /^[[:space:]]*/)
            indent = substr(line, RSTART, RLENGTH)
            key = line
            sub(/^[[:space:]]*/, "", key)
            sub(/[[:space:]]*=.*$/, "", key)
            print indent key " = \"" new_dlss_hash "\";"
            next
        }

        if (line ~ /^[[:space:]]*\};[[:space:]]*$/) {
            in_dlss = 0
        }
    }

    print line
}

END {
    if (!found_version) exit 2
    if (!found_github) exit 3
    if (!found_rev) exit 4
    if (!found_hash) exit 5
    if (!found_dlss) {
        print "Warning: dlssSdk block not found in file, only bbport was updated." > "/dev/stderr"
    }
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

if [[ "$UPDATED_VERSION" != "$VERSION" ]]; then
    echo "Error: Failed to update version." >&2
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
    echo "app-bbport.nix is already up to date."
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
echo "bbport Tag:   $LATEST_TAG (v $VERSION)"
echo "DLSS Tag:     $DLSS_LATEST_TAG"
echo "Backup saved: $BACKUP"
