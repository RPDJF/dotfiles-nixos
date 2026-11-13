#!/usr/bin/env bash
set -e

# Configuration
REPO="NVIDIA/DLSS"
BASE_DIR="$HOME/.dlss-sdk"

# Verify required dependencies
for cmd in curl jq unzip; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

echo "Checking for the latest NVIDIA DLSS release..."

# Fetch the latest release tag from GitHub API
LATEST_TAG=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r .tag_name)

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
    echo "Error: Failed to fetch the latest release tag from GitHub." >&2
    exit 1
fi

echo "Latest release found: $LATEST_TAG"

# Define destination directory for this version
TARGET_DIR="$BASE_DIR/$LATEST_TAG"

# Check if the version is already downloaded
if [ -d "$TARGET_DIR" ]; then
    echo "Version $LATEST_TAG is already present at:"
    echo "  $TARGET_DIR"
    echo "Skipping download (existing old versions are preserved)."
    exit 0
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Construct download URL and temporary zip path
ZIP_URL="https://github.com/$REPO/releases/download/$LATEST_TAG/ngx_dlss_demo_linux.zip"
ZIP_PATH="$TARGET_DIR/ngx_dlss_demo_linux.zip"

echo "Downloading $ZIP_URL..."
if ! curl -L -o "$ZIP_PATH" "$ZIP_URL"; then
    echo "Error: Download failed." >&2
    rm -rf "$TARGET_DIR"
    exit 1
fi

echo "Extracting and organizing files..."
TMP_EXTRACT_DIR=$(mktemp -d)
unzip -q "$ZIP_PATH" -d "$TMP_EXTRACT_DIR"

# Move the contents of DLSS_Sample_App directly to the target directory
if [ -d "$TMP_EXTRACT_DIR/DLSS_Sample_App" ]; then
    shopt -s dotglob
    mv "$TMP_EXTRACT_DIR/DLSS_Sample_App/"* "$TARGET_DIR/"
    shopt -u dotglob
else
    mv "$TMP_EXTRACT_DIR"/* "$TARGET_DIR/"
fi

# Clean up temp extraction folder and zip file
rm -rf "$TMP_EXTRACT_DIR"
rm -f "$ZIP_PATH"

echo "Success! DLSS $LATEST_TAG is ready at:"
echo "  $TARGET_DIR"
