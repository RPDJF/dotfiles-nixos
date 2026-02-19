#!/usr/bin/env bash
set -euo pipefail

sudo chown "$USER:users" /etc/nixos -R

machine_id=$(sudo cat /etc/machine-id | tr -d '\n')

salt_file="./etc/nixos/machine-id-salt.txt"
salt=$(<"$salt_file")
salt=${salt//$'\n'/}

hashed_id=$(printf "%s%s" "$salt" "$machine_id" | sha256sum | awk '{print $1}')

profile_dir="/etc/nixos/profiles/$hashed_id"
sudo mkdir -p "$profile_dir"

read -rp "Profile name for $hashed_id : " profile_name
sudo rm -f "/etc/nixos/profiles/$profile_name"
sudo ln -s "$hashed_id" "/etc/nixos/profiles/$profile_name"

echo "✅  Profile '$profile_name' → $profile_dir created."