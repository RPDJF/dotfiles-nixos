#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

needs_sudo() {
    [[ "$1" == /etc/* ]]
}

run_cmd() {
    if needs_sudo "$1"; then
        sudo "${@:2}"
    else
        "${@:2}"
    fi
}

backup_or_remove() {
    local target="$1"

    if [ -L "$target" ]; then
        echo "Removing symlink: $target"
        run_cmd "$target" rm "$target"
    elif [ -e "$target" ]; then
        echo "Backing up: $target -> ${target}.old-${TIMESTAMP}"
        run_cmd "$target" mv "$target" "${target}.old-${TIMESTAMP}"
    fi
}

echo "== Processing /etc =="

for item in "$REPO_DIR/etc/"*; do
    name="$(basename "$item")"
    target="/etc/$name"

    backup_or_remove "$target"

    echo "Linking $item -> $target"
    sudo ln -s "$item" "$target"
done


echo "== Processing \$HOME (excluding .config && .local) =="

for item in "$REPO_DIR/home/"* "$REPO_DIR/home/".*; do
    name="$(basename "$item")"

    # skip the special entries and let the .config loop handle .config
    if [ "$name" = "." ] || \
       [ "$name" = ".." ] || \
       [ "$name" = ".config" ] || \
       [ "$name" = ".local" ]; then
        continue
    fi

    target="$HOME/$name"

    echo $name
    echo backup_or_remove "$target"
    backup_or_remove "$target"

    echo "Linking $item -> $target"
    ln -s "$item" "$target"
done


echo "== Processing \$HOME/.config =="

mkdir -p "$HOME/.config"

for item in "$REPO_DIR/home/.config/"*; do
    name="$(basename "$item")"
    target="$HOME/.config/$name"

    backup_or_remove "$target"

    echo "Linking $item -> $target"
    ln -s "$item" "$target"
done

echo "== Processing \$HOME/.local =="

mkdir -p "$HOME/.local"

for item in "$REPO_DIR/home/.local/"*; do
    name="$(basename "$item")"

    # skip the special entries and let the share loop handle share
    if [ "$name" = "." ] || [ "$name" = ".." ] || [ "$name" = "share" ]; then
        continue
    fi

    target="$HOME/.local/$name"

    echo backup_or_remove "$target" 2
    backup_or_remove "$target"

    echo "Linking $item -> $target"
    ln -s "$item" "$target"
done

echo "== Processing \$HOME/.local/share =="

mkdir -p "$HOME/.local/share"

for item in "$REPO_DIR/home/.local/share/"*; do
    name="$(basename "$item")"

    # skip the special entries and let the share loop handle share
    if [ "$name" = "." ] || [ "$name" = ".." ] || [ "$name" = "icons" ]; then
        continue
    fi

    target="$HOME/.local/share/$name"

    backup_or_remove "$target"

    echo "Linking $item -> $target"
    ln -s "$item" "$target"
done

for item in "$REPO_DIR/home/.local/share/icons/"*; do
    name="$(basename "$item")"
    target="$HOME/.local/share/icons/$name"

    backup_or_remove "$target"

    echo "Linking $item -> $target"
    ln -s "$item" "$target"
done

echo "Done."

