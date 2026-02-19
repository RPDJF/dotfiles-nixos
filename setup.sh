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


echo "== Processing \$HOME (excluding .config) =="

for item in "$REPO_DIR/home/"* "$REPO_DIR/home/".*; do
    name="$(basename "$item")"

    # skip the special entries and let the .config loop handle .config
    if [ "$name" = "." ] || [ "$name" = ".." ] || [ "$name" = ".config" ]; then
        continue
    fi

    target="$HOME/$name"

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

echo "Done."

