# 📂 Dotfiles + NixOS

> ‘Purpose’ – This repo stores my NixOS system configuration **and** personal dotfiles.  
> By running a couple of tiny scripts I can spin up any machine, drop the right symlinks into `/etc` and `$HOME`, and instantly have _all_ my configs back.

---

## 🚀 Quick‑Start

I recommend first installing your NixOS on your drive before using this repo. While it's possible using this repo while installing NixOS, the scripts will target system-wide files (/etc, /home) instead of your mounted installation (/mnt/sda). Plus the profiles are based on your `/etc/machine-id` which will change between your installation media and your installed system.

```bash
# 1️⃣ Clone the repo somewhere safe
git clone https://github.com/your‑username/dotfiles-nixos.git ~/src/dotfiles-nixos
cd ~/src/dotfiles-nixos
```

### 1️⃣ Create a machine profile _(optional but recommended)_

‘Run **once** per machine to give your NixOS install a friendly name. Future versions of `init.sh` will also handle hostname and hardware moves.’

```bash
# Creates /etc/nixos/profiles/ and a readable symlink
./init.sh
```

### 2️⃣ Install the symlinks

‘This links everything from the repo into `/etc` and `$HOME` while safely backing up any existing files.’

```bash
# From the repo root
./setup.sh               # will prompt for sudo when needed
```

---

## 📂 Repository Layout

| Path                       | What it contains                                                                  |
| -------------------------- | --------------------------------------------------------------------------------- |
| `etc/`                     | System-level NixOS files (symlinked into **/etc**)                                |
| `home/`                    | Personal dotfiles (`.bashrc`, `.zshrc`, …) — ignores **.config/** and **.local/** |
| `home/.config/`            | Personal config files (`hypr`, `fastfetch`, …) — handled separately               |
| `home/.local/`             | User local data — handled separately, ignores **share/**                          |
| `home/.local/share/`       | User share data — handled separately, ignores **icons/**                          |
| `home/.local/share/icons/` | User icon themes — handled separately                                             |
| `home/.scripts/`           | Collection of personal scripts used for custom functionality                      |
| `init.sh`                  | Prepares `/etc/nixos/profiles/`, creates a human-readable profile symlink         |
| `setup.sh`                 | Backs up existing files, then creates the symlinks                                |

---

## 🛠️ Scripts in `home/.scripts/`

This directory contains several utility scripts that provide specialized functionality to enhance my Hyprland environment and system management:

### `hypr-animations.sh`

A script that creates animated borders around active windows when using OLED displays. It helps prevent image retention by continuously changing the border color and opacity while running in a loop, with CPU pinning for X3D CPUs to improve performance.

### `hypr-live-wallpaper-fetcher.sh`

Downloads, optimizes, and prepares live wallpapers from various sources for use with Hyprland. It detects your GPU hardware (NVIDIA, AMD, Intel) and uses appropriate encoding options to optimize videos for display. Works with YouTube-dl or yt-dlp to download videos from desktophut.com and other sources.

### `hypr-live-wallpaper.sh`

Controls live wallpapers in Hyprland by coordinating with the wallpaper fetcher script. It manages switching randomly between available wallpapers at regular intervals, skips changing during gaming sessions, and ensures that wallpaper processes are properly started/stopped.

### `hypr-service.sh`

A generic service launcher that starts commands with retry logic. It's used to start critical components like waybar, hypridle, mako, and others with a maximum of 10 retry attempts, logging each attempt.

### `hypr-toggle-hdr.sh`

Toggles between HDR and SDR display settings in Hyprland by modifying monitor configuration files. This enables easy switching between high dynamic range and standard dynamic range modes for displays that support both.

### `lazy-docker-containers.sh`

An interactive wrapper for managing Docker containers using docker-compose. It provides commands to start, stop, view logs, or manage all your containerized applications with a built-in Traefik proxy management system.

### `start-hyprland-keyring.sh`

Starts GNOME Keyring with secrets and SSH support before launching Hyprland. Ensures proper environment variables are set for password managers and SSH agent integration within the Hyprland session.

### `swayosd-wrapper.sh`

A wrapper around swayosd-client that provides volume, brightness, and media control functionality with additional sound feedback for user actions.

### `update-nix-unstable.sh`

Updates the NixOS channel to the unstable version and performs a system rebuild using `nixos-rebuild switch`.

### `wg-ipv4.sh`

Manages WireGuard VPN connections by resolving IPv4 addresses of endpoints and handling connection lifecycle (up/down). It stores status information in cache and provides notifications.

### `waybar-peek.py`

A Python script that shows/hides the Waybar based on cursor position, improving window management workflow by hiding the bar when not needed and showing it when the cursor approaches.

---

## 🔎 Behavior Summary

Each level is synced independently:

- `home/` does **not** touch `.config/` or `.local/`
- `.config/` is handled on its own
- `.local/` is handled on its own (excluding `share/`)
- `.local/share/` is handled on its own (excluding `icons/`)
- `.local/share/icons/` is handled on its own

This keeps recursion clean and prevents overlapping symlink logic.

---

## 🤔 Why symlinks instead of Home Manager?

I love the idea of Home Manager, but for my workflow a **plain‑old‑symlink** approach feels cleaner and less of a struggle:

- **Zero extra layer** – Home Manager adds its own Nix modules and a separate activation step. With raw symlinks I keep the chain short: repo ➜ `/etc`/`$HOME`.
- **Full control** – I can see exactly what file ends up where, and I can tweak the backup logic in `setup.sh` without fighting against Home Manager’s declarative model.
- **Portability** – The same scripts work on any Linux distro that supports symlinks, not just NixOS. If I ever spin a VM that isn’t Nix‑enabled, the repo still does its job.

Bottom line: symlinks give me **predictability**, **speed**, and **cross‑platform freedom**—exactly what I need for a fast‑moving dev/gamer life.

---

## 🛠️ What `init.sh` Currently Does

_Preprepares a per-machine profile directory for both NixOS and Hyprland, using a stable hashed machine identity._

---

### 1️⃣ Ownership Adjustment

Runs:

```bash
sudo chown "$USER:users" /etc/nixos -R
```

This allows the script to manage `/etc/nixos/profiles/`.  
(Review permissions if you prefer tighter security boundaries.)

---

### 2️⃣ Stable Machine Hash Generation

The script:

- Reads `/etc/machine-id`
- Reads `etc/nixos/machine-id-salt.txt`
- Concatenates `salt + machine-id`
- Generates a SHA-256 hash

That hash becomes the **real profile ID**.

Why this matters:

- Even if two machines share the same hostname
- Even if two machines use the same profile name

Their `/etc/machine-id` will differ, so their hashed ID will always be unique.

This guarantees:

- No collisions
- No accidental overwrites
- No broken deployments due to duplicate names

The **hash is the source of truth** — not the human-readable profile name.

---

### 3️⃣ Profile Directories Created

Using the same hashed ID, the script creates:

```
/etc/nixos/profiles/<hashed-id>
$HOME/.config/hypr/hyprland.profiles.d/<hashed-id>
```

This means:

- The same machine identity is shared between **NixOS configuration** and **Hyprland configuration**
- Both systems stay aligned to the same device-specific profile

---

### 4️⃣ Human-Readable Symlink (Alias)

The script creates human-readble symlinks:

```
/etc/nixos/profiles/<profileName> → <hashed-id>
$HOME/.config/hypr/hyprland.profiles.d/<profileName> → <hashed-id>
```

These symlinks exist **only for convenience**:

- Easier navigation in IDEs
- Cleaner directory structure
- Human-friendly profile switching

The system does **not** rely on the name — only on the hashed directory.

---

### 5️⃣ `current` Symlink Handling (Hyprland)

The script regenerates:

```
$HOME/.config/hypr/hyprland.profiles.d/current → <profileName>
```

By default, current symlink is linked to `default` profile

This makes it easy for Hyprland to reference the active profile.

Each time `init.sh` runs:

- The `current` symlink is removed
- It is recreated pointing to the selected profile

---

### 6️⃣ Git Behavior

The file:

```
home/.config/hypr/hyprland.profiles.d/current
```

is marked with:

```bash
git update-index --skip-worktree
```

This means:

- Git tracks the file
- But ignores working-tree modifications
- So switching machines or profiles will not create Git noise

The `current` symlink is intentionally **machine-local state**, not repository state.

---

### 📌 Important Design Principle

- The **hashed machine ID directory** is permanent and authoritative.
- The **profile name symlink** is just a readable alias.
- The **`current` symlink** is regenerated state.
- The same hashed identity is used across:
  - `/etc/nixos/profiles/`
  - `~/.config/hypr/hyprland.profiles.d/`

This keeps device-specific configuration isolated, stable, and collision-proof.

## 🔧 What `setup.sh` Does

_Safely backs up anything that already exists, then replaces it with symlinks from the repository._

The script uses strict mode:

```bash
set -euo pipefail
shopt -s nullglob
```

- Fails immediately on errors
- Prevents undefined variable usage
- Avoids globbing issues when directories are empty

All backup logic is centralized in `backup_or_remove()`:

- If target is a **symlink** → remove it
- If target is a **file or directory** → rename it to  
  `<name>.old-<TIMESTAMP>`
- Timestamp format: `YYYYMMDD-HHMMSS`

If the path is under `/etc`, the script automatically uses `sudo`.

---

### 1️⃣ Process `etc/`

For every file in `repo/etc/`:

- Target: `/etc/<name>`
- Remove existing symlink OR backup existing file/dir
- Create new symlink (with `sudo`)

---

### 2️⃣ Process `home/` (excluding `.config` and `.local`)

For every entry in `repo/home/`:

- Skips:
  - `.config`
  - `.local`
- Target: `$HOME/<name>`
- Backup/remove existing target
- Create symlink

This keeps top-level dotfiles isolated from nested config logic.

---

### 3️⃣ Process `home/.config/`

- Ensures `$HOME/.config` exists
- For each entry:
  - Target: `$HOME/.config/<name>`
  - Backup/remove existing
  - Create symlink

Handled independently from `home/`.

---

### 4️⃣ Process `home/.local/`

- Ensures `$HOME/.local` exists
- Skips:
  - `share`
- Targets: `$HOME/.local/<name>`
- Backup/remove existing
- Create symlink

`.local` is handled separately from `home/` and `.config`.

---

### 5️⃣ Process `home/.local/share/`

- Ensures `$HOME/.local/share` exists
- Skips:
  - `icons`
- Targets: `$HOME/.local/share/<name>`
- Backup/remove existing
- Create symlink

Handled independently from parent `.local`.

---

### 6️⃣ Process `home/.local/share/icons/`

- Targets: `$HOME/.local/share/icons/<name>`
- Backup/remove existing
- Create symlink

Icons are handled separately to avoid overlap with other `share/` entries.

---

### 🔐 Backup Naming

Backups are created like:

```
<file>.old-20250219-153000
```

This includes critical files like:

- `configuration.nix`
- Any existing dotfiles
- Any `.config` or `.local` entries

Nothing is deleted permanently — everything is preserved with a timestamp.

---

### 🧠 Design Principle

Each directory level is processed independently:

- `home/` ignores `.config/` and `.local/`
- `.config/` is handled alone
- `.local/` ignores `share/`
- `.local/share/` ignores `icons/`
- `.local/share/icons/` is handled last

This prevents recursive overlap and guarantees predictable symlink behavior.

Your system now reflects the repository exactly — with all previous state safely backed up.

---

## ♻️ Restoring Backups

'Nothing gets deleted; everything gets renamed with a timestamp, so you can roll back whenever you need.'

```bash
# Restore a system file (e.g., hardware config)
sudo mv /etc/hardware-configuration.nix.old-20250219-153000 \
         /etc/hardware-configuration.nix

# Restore a global NixOS config
sudo mv /etc/configuration.nix.old-20250219-153000 \
         /etc/configuration.nix

# Restore a home dotfile
mv "$HOME/.bashrc.old-20250219-153000" "$HOME/.bashrc"
```

If you moved a hardware file into a profile, just copy it back from the profile directory before running `setup.sh` again.

---

## ⚠️ Safety Tips & Recommendations

- `init.sh` currently changes ownership of `/etc/nixos`; edit the script or run it manually if that bugs you.
- No built‑in dry‑run mode – try the scripts in a disposable VM first, or add a `--dry-run` flag (happy to help you code that).

---

## 🌟 Making It Yours

The repo is **dynamic** – anyone can clone it, wipe out my personal configs, drop in theirs, and the scripts will take care of the rest. Just take a look at [📂 Repo Layout](#📂-repository-layout)

1. Delete or rename any files you don’t need under `etc/`, `home/.config` or `home/`. Since `home/.config` uses its own loop, you may want to keep it and remove files under `home/.config` instead. Same for `.local/share` and `.local/share/icons`.
2. Add your own configuration files using the same directory layout.
3. Run `./setup.sh` and watch the magic happen.

You can use `./init.sh` in order to create your own profile under `/etc/nixos/profiles`, just make sure to correctly import those configurations.

> Remember: the **profile** folder is for _device‑only_ files (hardware config, future hostname settings). All other `.nix` files belong to the global config.

---

## 📌 Future Enhancements (TODO)

- Extend `init.sh` to automatically **move** `hardware-configuration.nix` (and any other hardware‑specific `.nix` files) into the newly created profile.
- Add a `--dry-run` flag to `setup.sh` for previewing actions.
- Create a `restore.sh` helper that lists all `.old-<timestamp>` backups and lets you pick which to revert.

---
