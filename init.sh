#!/usr/bin/env bash
set -euo pipefail

sudo chown "$USER:users" /etc/nixos -R

machine_id=$(sudo cat /etc/machine-id | tr -d '\n')

salt_file="./etc/nixos/machine-id-salt.txt"
salt=$(<"$salt_file")
salt=${salt//$'\n'/}

hashed_id=$(printf "%s%s" "$salt" "$machine_id" | sha256sum | awk '{print $1}')

nix_profile_dir="/etc/nixos/profiles/$hashed_id"
hypr_profile_dir="$HOME/.config/hypr/hyprland.profiles.d/$hashed_id"
sudo mkdir -p "$nix_profile_dir"
mkdir -p "$hypr_profile_dir"

read -rp "Profile name for $hashed_id : " profile_name
sudo rm -f "/etc/nixos/profiles/$profile_name"
sudo ln -s "$hashed_id" "/etc/nixos/profiles/$profile_name"
rm -f "$HOME/.config/hypr/hyprland.profiles.d/$profile_name"
ln -s "$hashed_id" "$HOME/.config/hypr/hyprland.profiles.d/$profile_name"

# change current profile symlink to point to the new profile
rm -f "$HOME/.config/hypr/hyprland.profiles.d/current"
ln -s "$profile_name" "$HOME/.config/hypr/hyprland.profiles.d/current"

# mark the tracked file so Git ignores working-tree modifications
git update-index --skip-worktree home/.config/hypr/hyprland.profiles.d/current

echo "✅  Nix Profile '$profile_name' → $nix_profile_dir created."
echo "✅  Hyprland Profile '$profile_name' → $hypr_profile_dir created."