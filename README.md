**Dotfiles NixOS**

- **Purpose**: This repository holds NixOS system configuration and user dotfiles arranged so you can install them by creating safe symlinks into `/etc` and `$HOME`.

**Quick Start**
- **Clone repo**: Clone this repository to a safe location (example: `~/src/dotfiles-nixos`).
- **Create machine profile (optional)**: To prepare a profile for this machine run:

```bash
# Run once per machine to create a profile symlink in /etc/nixos/profiles
sudo ./init.sh
```

- **Install symlinks**: To link files from the repo into `/etc` and your home directory:

```bash
# From the repo root
./setup.sh
# If you prefer to ensure sudo credentials up-front for /etc changes
sudo -v && ./setup.sh
```

**Repository layout**
- `etc/` : system-level NixOS configuration that will be linked into `/etc/`.
- `home/` : user-level dotfiles and a `.config/` subtree that will be linked into `$HOME` and `$HOME/.config` respectively.
- `init.sh` : helper to prepare `/etc/nixos/profiles/` and create a named profile symlink for this machine.
- `setup.sh` : main installer script that backs up existing files and creates symlinks from the repo into the system and home.

**What `init.sh` does**
- **Purpose**: prepare a per-machine profile directory under `/etc/nixos/profiles/` and create a human-friendly symlink for it.
- **Actions**:
	- Runs `sudo chown $USER:users /etc/nixos -R` to ensure the current user can write into `/etc/nixos` (review before running).
	- Reads `/etc/machine-id` into `machineId` and creates `/etc/nixos/profiles/$machineId`.
	- Prompts: `Profile name for $machineId : ` and creates a symlink `/etc/nixos/profiles/$profileName -> $machineId`.
- **When to run**: once per machine when you want to register a readable profile name for the machine. Requires `sudo`.

**What `setup.sh` does**
- **Purpose**: create symlinks from this repository into `/etc` and `$HOME`, backing up or removing existing targets safely.
- **Key behaviors**:
	- Runs with strict bash flags: `set -euo pipefail` and enables `nullglob` for safe glob handling.
	- Determines the repository root with `REPO_DIR` so it can be run from anywhere inside the repo.
	- For each entry in `etc/`:
		- If `/etc/<name>` is a symlink, it removes it.
		- If `/etc/<name>` exists, it moves it to `/etc/<name>.old-<TIMESTAMP>`.
		- Creates a symlink from `<repo>/etc/<name>` -> `/etc/<name>` (uses `sudo` automatically).
	- For each entry in `home/` (excluding `.config`): same backup or remove logic, then links into `$HOME/<name>`.
	- For each entry in `home/.config/`: ensures `$HOME/.config` exists, backs up existing items and links each entry into `$HOME/.config/<name>`.
	- Backups use a timestamp suffix: `.old-YYYYMMDD-HHMMSS`.

**Backups & Restore**
- Existing files are not deleted; they are moved to `<target>.old-<TIMESTAMP>` before any new symlink is created.
- To restore a backed-up file:

```bash
# Example: restore /etc/some.conf from its backup
sudo mv /etc/some.conf.old-20250219-153000 /etc/some.conf

# Example: restore a home dotfile
mv "$HOME/.bashrc.old-20250219-153000" "$HOME/.bashrc"
```

**Safety notes & recommendations**
- Review the contents of `etc/` and `home/` before running `setup.sh`.
- `init.sh` changes ownership of `/etc/nixos` to the current user — inspect the script and consider running it manually if you prefer specific permissions.
- There is no dry-run mode in `setup.sh`. If you want to test what will happen, run the script in a disposable VM or add a `--dry-run` option (I can add this if you want).
- If you want to avoid `sudo` prompts popping up repeatedly, run `sudo -v` before `./setup.sh` to refresh credentials.

**Next steps / Helpful additions**
- Add a `--dry-run` flag to `setup.sh` to preview changes without touching the filesystem.
- Add a `restore.sh` helper to list and restore `.old-<TIMESTAMP>` backups.

