#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

REPO="GloriousEggroll/proton-ge-custom"

COMPAT_DIR="$HOME/.local/share/Steam/compatibilitytools.d"
LATEST_DIR="$COMPAT_DIR/GE-Proton-latest"

API_URL="https://api.github.com/repos/${REPO}/releases/latest"
RELEASES_API_URL="https://api.github.com/repos/${REPO}/releases?per_page=100"

MODE="${1:-latest}"

# ------------------------------------------------------------
# Validate mode
# ------------------------------------------------------------

if [[ "$MODE" != "latest" && "$MODE" != "interactive" ]]; then
    echo "Usage: $0 [interactive]"
    exit 1
fi

# ------------------------------------------------------------
# Detect architecture
# ------------------------------------------------------------

case "$(uname -m)" in
    x86_64)
        ARCH="x86_64"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        ;;
    *)
        echo "Error: Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

echo "Architecture: $ARCH"

mkdir -p "$COMPAT_DIR"

# ------------------------------------------------------------
# Temporary directory
# ------------------------------------------------------------

TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf -- "$TMP_DIR"
}

trap cleanup EXIT

# ------------------------------------------------------------
# Get release information
# ------------------------------------------------------------

if [[ "$MODE" == "interactive" ]]; then

    echo "Fetching available GE-Proton releases..."

    if ! releases_json="$(
        curl -fsSL \
            --connect-timeout 10 \
            --max-time 30 \
            "$RELEASES_API_URL"
    )"; then
        echo "Error: Could not contact GitHub." >&2
        exit 1
    fi

    # --------------------------------------------------------
    # Build list of releases with a matching architecture
    # --------------------------------------------------------

    mapfile -t releases < <(
        jq -r --arg arch "$ARCH" '
            .[]
            | select(.draft == false and .prerelease == false)
            | select(
                any(
                    .assets[];
                    (.name | endswith("-" + $arch + ".tar.gz"))
                )
            )
            | "\(.tag_name)\t\(.published_at)"
        ' <<< "$releases_json"
    )

    if [[ "${#releases[@]}" -eq 0 ]]; then
        echo "Error: No compatible GE-Proton releases found." >&2
        exit 1
    fi

    # --------------------------------------------------------
    # Display releases
    # --------------------------------------------------------

    echo
    echo "Available GE-Proton versions:"
    echo

    for i in "${!releases[@]}"; do
        release="${releases[$i]}"

        version="${release%%$'\t'*}"
        published="${release#*$'\t'}"
        published="${published%%T*}"

        printf "  %2d) %s (%s)\n" \
            "$((i + 1))" \
            "$version" \
            "$published"
    done

    echo

    # --------------------------------------------------------
    # Ask user to choose
    # --------------------------------------------------------

    while true; do
        read -rp "Select version [1-${#releases[@]}]: " selection

        if [[ "$selection" =~ ^[0-9]+$ ]] &&
           (( selection >= 1 && selection <= ${#releases[@]} )); then
            break
        fi

        echo "Invalid selection."
    done

    selected="${releases[$((selection - 1))]}"
    version="${selected%%$'\t'*}"

    echo
    echo "Selected version: $version"
    echo
    echo "GE-Proton-latest will NOT be changed."

    # --------------------------------------------------------
    # Find download URL
    # --------------------------------------------------------

    download_url="$(
        jq -r \
            --arg tag "$version" \
            --arg arch "$ARCH" '
                .[]
                | select(.tag_name == $tag)
                | .assets[]
                | select(.name | endswith("-" + $arch + ".tar.gz"))
                | .browser_download_url
            ' <<< "$releases_json" |
        head -n1
    )"

    if [[ -z "$download_url" ]]; then
        echo "Error: Could not find ${ARCH} archive for ${version}." >&2
        exit 1
    fi

else

    # --------------------------------------------------------
    # Latest release
    # --------------------------------------------------------

    echo "Checking latest GE-Proton release..."

    if ! release_json="$(
        curl -fsSL \
            --connect-timeout 10 \
            --max-time 30 \
            "$API_URL"
    )"; then
        echo "Error: Could not contact GitHub." >&2
        exit 1
    fi

    version="$(
        jq -r '.tag_name // empty' <<< "$release_json"
    )"

    if [[ -z "$version" ]]; then
        echo "Error: Could not determine latest GE-Proton version." >&2
        exit 1
    fi

    download_url="$(
        jq -r --arg arch "$ARCH" '
            .assets[]
            | select(
                .name
                | endswith("-" + $arch + ".tar.gz")
            )
            | .browser_download_url
        ' <<< "$release_json" |
        head -n1
    )"

    if [[ -z "$download_url" ]]; then
        echo "Error: Could not find ${ARCH} archive for ${version}." >&2
        exit 1
    fi

    echo "Latest version: $version"

fi

# ------------------------------------------------------------
# Download
# ------------------------------------------------------------

archive_name="$(basename "$download_url")"
archive="$TMP_DIR/$archive_name"

echo "Archive:        $archive_name"
echo
echo "Downloading GE-Proton $version..."

curl -fL \
    --connect-timeout 10 \
    --max-time 600 \
    --progress-bar \
    "$download_url" \
    -o "$archive"

# ------------------------------------------------------------
# Extract
# ------------------------------------------------------------

echo
echo "Extracting..."

extract_dir="$TMP_DIR/extracted"

mkdir -p "$extract_dir"

tar -xzf "$archive" -C "$extract_dir"

# ------------------------------------------------------------
# Find extracted Proton directory
# ------------------------------------------------------------

proton_dir="$(
    find "$extract_dir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name 'GE-Proton*' \
        ! -name 'GE-Proton-latest' |
    head -n1
)"

if [[ -z "$proton_dir" ]]; then
    echo "Error: Archive did not contain a GE-Proton directory." >&2
    exit 1
fi

proton_name="$(basename "$proton_dir")"

echo "Extracted: $proton_name"

# ------------------------------------------------------------
# Install versioned Proton
# ------------------------------------------------------------

versioned_dir="$COMPAT_DIR/$proton_name"

if [[ -e "$versioned_dir" ]]; then

    echo
    echo "Version already exists:"
    echo "  $versioned_dir"

else

    echo
    echo "Installing:"
    echo "  $versioned_dir"

    cp -a "$proton_dir" "$versioned_dir"

fi

# ------------------------------------------------------------
# Update GE-Proton-latest
# ------------------------------------------------------------

if [[ "$MODE" == "latest" ]]; then

    echo
    echo "Replacing GE-Proton-latest..."

    # Remove directory, symlink, or file.
    if [[ -e "$LATEST_DIR" || -L "$LATEST_DIR" ]]; then
        rm -rf -- "$LATEST_DIR"
    fi

    # Make a real copy, NOT a symlink.
    cp -a "$versioned_dir" "$LATEST_DIR"

    echo
    echo "GE-Proton-latest:"
    echo "  $LATEST_DIR"

else

    echo
    echo "Interactive mode:"
    echo "GE-Proton-latest was NOT changed."

fi

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------

echo
echo "Done."
echo
echo "Installed:"
echo "  $versioned_dir"

