# 📂 Dotfiles + NixOS

> ‘Purpose’ – This repo stores my NixOS system configuration **and** personal dotfiles.  
> By running a couple of tiny scripts I can spin up any machine, drop the right symlinks into `/etc` and `$HOME`, and instantly have *all* my configs back.

---

## 🚀 Quick‑Start

```bash
# 1️⃣ Clone the repo somewhere safe
git clone https://github.com/your‑username/dotfiles-nixos.git ~/src/dotfiles-nixos
cd ~/src/dotfiles-nixos
```

### 1️⃣ Create a machine profile *(optional but recommended)*  

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

| Path      | What it contains |
|-----------|-------------------|
| `etc/`    | System‑level NixOS files (symlinked into **/etc**) |
| `home/`   | Personal dotfiles (`.bashrc`, `.zshrc`, …) ignores **.config/** |
| `home/.config`   | Personal .config files (`hypr`, `fastfetch`, …) ignores **.config/** |
| `init.sh` | Prepares `/etc/nixos/profiles/`, creates a human‑readable profile symlinkg |
| `setup.sh`| Backs up existing files, then creates the symlinks |

---

## 🛠️ What `init.sh` Currently Does

‘Prepare a per‑machine profile directory under `/etc/nixos/profiles/` and give it a nice name.’

1. **Ownership tweak** – runs `sudo chown "$USER:users" /etc/nixos -R` so the script can manage the profile folder (review if you want tighter perms).  
2. **Hash generation** – reads `/etc/machine-id`, mixes in `etc/nixos/machine-id-salt.txt`, and builds a SHA‑256 hash.  
3. **Symlink creation** – prompts for a *profile name* and creates  

   ```
   /etc/nixos/profiles/<profileName> → /etc/nixos/profiles/<hashed-id>
   ```

4. **Future roadmap** – will also set the hostname, move hardware‑specific `.nix` files into the profile, etc. (not there yet).  

> **Note:** The profile folder is for *device‑specific* files only (e.g., `hardware-configuration.nix`). Global NixOS config files like `configuration.nix` live outside the profile.

---

## 🔧 What `setup.sh` Does

‘Safely backup anything that already exists, then drop in my repo’s version.’  

1. **Process `etc/` entries**  
   - If `/etc/<name>` is a symlink → remove it.  
   - If it’s a regular file/dir → move to `/etc/<name>.old-<TIMESTAMP>`.  
   - Create a new symlink from the repo to `/etc/<name>` (via `sudo`).  
2. **Process `home/` entries (excluding `.config`)** – same backup‑then‑link logic, targeting `$HOME`.  
3. **Process `home/.config/` entries** – ensures `$HOME/.config` exists, then backs up & links each item.  

> **Backup naming** – files get a timestamp suffix like `.old-20250219-153000`. This includes `configuration.nix`; if you keep your own version, it will be saved as `configuration.nix.old-<timestamp>` and you can restore it later.

---

## ♻️ Restoring Backups

‘Nothing gets deleted; everything gets renamed with a timestamp, so you can roll back whenever you need.’

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

The repo is **dynamic** – anyone can clone it, wipe out my personal configs, drop in theirs, and the scripts will take care of the rest. Just take a look at [📂 Repo Layout](#repository-layout)

1. Delete or rename any files you don’t need under `etc/`, `home/.config` or `home/`. Since `home/.config` uses its own loop, you may want to keep it and remove files under `home/.config` instead.
2. Add your own configuration files using the same directory layout.  
3. Run `./setup.sh` and watch the magic happen.

You can use `./init.sh` in order to create your own profile under `/etc/nixos/profiles`, just make sure to correctly import those configurations.

> Remember: the **profile** folder is for *device‑only* files (hardware config, future hostname settings). All other `.nix` files belong to the global config.

---

## 📌 Future Enhancements (TODO)

- Extend `init.sh` to automatically **move** `hardware-configuration.nix` (and any other hardware‑specific `.nix` files) into the newly created profile.  
- Add a `--dry-run` flag to `setup.sh` for previewing actions.  
- Create a `restore.sh` helper that lists all `.old-<timestamp>` backups and lets you pick which to revert.  

---
