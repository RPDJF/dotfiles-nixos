# dotfiles-nixos 🐧

Personal NixOS, Hyprland, and desktop configuration managed with repository
symlinks. The repository is tailored to the author's machines and workflow;
it is not a generic NixOS installer or a standalone Home Manager module.

## 📦 What is here

- A NixOS configuration for a Limine-booted, Wayland-first desktop.
- Machine-specific NixOS and Hyprland profiles selected from `/etc/machine-id`.
- Hyprland, Waybar, Kitty, Rofi, Mako, GTK, fastfetch, VS Code, and related
  user configuration.
- Docker Compose definitions for Traefik and local AI services.
- Custom Nix packages for BlackShark Linux and HyprCapture.
- Scripts for power management, wallpapers, HDR, backups, WireGuard, Docker,
  package updates, and desktop utilities.

The configuration assumes NixOS, systemd, Hyprland, and the `ruipa` user. It
also contains hardware-specific paths, hostnames, disk identifiers, and local
network names, so review it before using it on another machine.

## 🚀 Quick start

> [!WARNING]
> **Do not run `./setup.sh` unchanged on a new machine.** This repository is
> preconfigured for the author's `ruipa` user and hardware. Replace the user,
> machine profile, disk and network settings first. The production credentials
> file `etc/nixos/secrets/fs-backups-creds.env` is intentionally missing from
> a clean checkout; create it locally only if you use the CIFS backup share.

### ⏱️ Before the first command

1. Replace every `ruipa` and `/home/ruipa` reference with your username.
2. Replace the author's profile directories and hardware files with your own.
3. Replace `etc/nixos/machine-id-salt.txt` with a new stable private salt.
4. Create `etc/nixos/secrets/fs-backups-creds.env` from
  `etc/nixos/secrets/fs-backups-creds.env.example` only for CIFS backups.
5. Review hostnames, disk UUIDs, mount paths, GPU settings, firewall rules, and
  `extra-hosts.nix` before rebuilding.

The detailed cleanup and configuration instructions are in [🧹 Make it yours:
fresh-install cleanup](#make-it-yours-fresh-install-cleanup) and [✅
Fresh-install requirements](#fresh-install-requirements) below. A new machine
can use the symlink workflow without CIFS: remove the CIFS filesystem entry
from its profile and do not use `home-backup.sh`.

Completely install NixOS first, then clone this repository and run the scripts from its
root. The scripts target the running system's `/etc` and `$HOME`; they do not
target an installation mounted at `/mnt`.

```bash
git clone <repository-url> ~/src/dotfiles-nixos
cd ~/src/dotfiles-nixos
./init.sh
./setup.sh
```

`init.sh` must run on the target installation because it reads that system's
`/etc/machine-id`. `setup.sh` asks for `sudo` as needed, but it does not run a
NixOS rebuild. After linking the files, rebuild explicitly:

```bash
sudo nixos-rebuild switch
```

The repository currently has two named machine profiles:

| Profile | Intended machine |
| --- | --- |
| `nb-nixyoga` | AMD laptop, Swiss keyboard, encrypted root, hostname `nb-nixyoga` |
| `ws-nixosx3d` | NVIDIA workstation, extra storage and CIFS backup mount, hostname `ws-nixosx3d` |

The profile files contain the authoritative hardware details. The names above
are aliases, not the values used by the NixOS import logic.

## 🧭 Learn quickly

Start with these linked subtitles in this order. Each subtitle scrolls to the
matching explanation below. Filenames are intentionally plain code text.

### [1. 🔗 Follow the symlinks](#read-setup)

Read `setup.sh` to see how repository paths become system and home symlinks.

### [2. 🧭 Create a machine profile](#read-profiles)

Read `init.sh` to see how a machine gets its hashed NixOS and Hyprland profile.

### [3. ❄️ Enter NixOS](#read-nixos)

Read `etc/nixos/configuration.nix`, the NixOS entry point and import list.

### [4. 🖥️ Inspect machine hardware](#read-hardware)

Browse `etc/nixos/profiles/` for hardware and machine-specific Nix settings.

### [5. 🪟 Build the Hyprland session](#read-hyprland)

Read `home/.config/hypr/hyprland.lua`, the desktop entry point. Its modules and
profile loader build the Hyprland session.

### [6. 🛠️ Explore the command toolbox](#read-scripts)

Browse `home/.scripts/` for desktop and maintenance commands.

### [7. 🐳 Start local services](#read-docker)

Browse `home/.docker-composers/` for optional Docker Compose services.

The central flow is:

```text
machine-id + salt
      |
      v
profile hash
  /          \
  v            v
NixOS       Hyprland
profile     Lua profile
  |            |
 nixos-      hyprland
 rebuild     reload
```

NixOS describes the operating system declaratively. Hyprland describes the
graphical session separately. `setup.sh` only connects files to their runtime
locations; `nixos-rebuild` evaluates and activates the Nix configuration.

<a id="read-profiles"></a>
## 🖥️ How machine profiles work

Both NixOS and Hyprland calculate the same profile ID:

```text
sha256(machine-id-salt + /etc/machine-id)
```

`etc/nixos/configuration.nix` imports:

```text
/etc/nixos/profiles/<hash>/profile.nix
```

`home/.config/hypr/hyprland.d/modules/70_profile_loader.lua` loads Lua files
from:

```text
$HOME/.config/hypr/hyprland.profiles.d/<hash>/
```

Run `./init.sh` once per installation to create both hashed directories. It
prompts for a readable alias and creates that alias in both profile roots.
The script also recursively changes ownership of `/etc/nixos` to
`$USER:users`, then runs `hyprctl reload`.

The hashed directory is authoritative. `init.sh` does not move hardware files,
select a hostname, or create a `current` Hyprland symlink. The loader computes
the hash directly. Any `current` symlink mentioned by older documentation is
not managed by this repository.

`machine-id-salt.txt` is required for the intended profile scheme. Keep it
consistent with the existing profile directories and treat it as sensitive
repository metadata, even though it is not a password.

<a id="read-setup"></a>
## 🔗 `setup.sh`

`setup.sh` backs up an existing target before linking the repository entry.
Existing symlinks are removed; existing files and directories are renamed to:

```text
<path>.old-YYYYMMDD-HHMMSS
```

It processes these levels independently to avoid recursive overlap:

| Repository path | Target | Notes |
| --- | --- | --- |
| `etc/*` | `/etc/*` | Requires `sudo` for linking and backups |
| `home/*` | `$HOME/*` | Skips `.config` and `.local` |
| `home/.config/*` | `$HOME/.config/*` | Creates `.config` if needed |
| `home/.local/*` | `$HOME/.local/*` | Skips `share` |
| `home/.local/share/*` | `$HOME/.local/share/*` | Skips `icons` |
| `home/.local/share/icons/*` | `$HOME/.local/share/icons/*` | Processed separately |

There is no dry-run mode and no automatic restore command. Verify the target
paths before running it, especially on a machine with existing system or
desktop configuration.

Example restore:

```bash
sudo mv /etc/nixos/configuration.nix.old-YYYYMMDD-HHMMSS \
  /etc/nixos/configuration.nix
mv "$HOME/.bashrc.old-YYYYMMDD-HHMMSS" "$HOME/.bashrc"
```

<a id="read-nixos"></a>
<a id="read-hardware"></a>
## ❄️ NixOS configuration

`etc/nixos/configuration.nix` is the entry point. It enables or imports:

- Limine with GRUB disabled, EFI variables, and `linuxPackages_zen`.
- Nix flakes and the `nix-command` experimental feature.
- Daily automatic upgrades at `11:00` without automatic reboot.
- Weekly garbage collection of generations older than 30 days.
- Hyprland-compatible XDG portals and `direnv`.
- Desktop modules in `desktop-manager.nix`, `environment.nix`, `fonts.nix`,
  `boot-animation.nix`, `users.nix`, `packages.nix`, and `extra-hosts.nix`.

The package configuration includes Steam, Gamescope, GameMode, Docker,
Flatpak, NVIDIA container support, WireGuard, Wine, OBS, browsers, Discord
with Vencord, Heroic, Jellyfin Desktop, development tools, and Wayland
utilities. It also installs the BlackShark Linux and HyprCapture custom apps.

The workstation profile additionally configures NVIDIA support, storage
mounts, a CIFS backup share, PipeWire tuning, Xbox controller support, and
Steam Remote Play firewall ports. The laptop profile configures its encrypted
root, swap, AMD graphics, keyboard layout, and hardware-specific mounts.

<a id="read-hyprland"></a>
## 🪟 Desktop configuration

The main user configuration lives under `home/.config/`:

- `hypr/`: modular Hyprland Lua configuration, startup, input, animation,
  lock/idle settings, plugins, and machine profile loading.
- `waybar/`: bar layout, styles, GPU and battery modules, and workspace tools.
- `kitty/`, `rofi/`, `mako/`, `btop/`, `clipse/`, `nwg-look/`, and GTK files:
  terminal, launcher, notifications, system monitor, clipboard, and theme
  configuration.
- `fastfetch/`: fastfetch configuration, custom fetch script, and image assets.
- `Vencord/`, `opencode/`, and `Code/User/`: application configuration.
- `.local/share/icons/`: the Bibata Modern Ice cursor theme.

## 🧰 Technology stack

| Technology | Role in this repository |
| --- | --- |
| **Nix** | Reproducible language and package/build system used by the `.nix` files. |
| **NixOS** | Declarative Linux distribution configuration, services, boot, users, packages, and hardware. |
| **NixOS modules** | The `*.nix` modules compose system settings through imports and option declarations. |
| **systemd** | Starts services, runs automatic upgrades and garbage collection, manages Docker, and runs `blacksharkd`. |
| **Limine** | EFI bootloader configured here instead of GRUB. |
| **Wayland** | Modern display protocol used by the graphical session. |
| **Hyprland** | Wayland compositor and window manager. Its Lua files configure keybindings, startup, monitors, input, and animations. |
| **Lua** | Hyprland configuration language used for shared modules and machine-specific profiles. |
| **Waybar** | Status bar with custom Bash modules for GPU, batteries, and workspaces. |
| **Bash** | Shell used by setup, profile initialization, desktop controls, backup, networking, and update scripts. |
| **Python** | Used by `waybar-peek.py` for cursor-aware Waybar behavior. |
| **Docker** | Container runtime enabled by NixOS for isolated local services. |
| **Docker Compose** | YAML-based definitions for Traefik and Ollama. |
| **Traefik** | Local reverse proxy for the Compose services and `.local.lan` hostnames. |
| **Ollama** | Local large-language-model service, configured with NVIDIA access in its Compose stack. |
| **NVIDIA / CUDA support** | GPU drivers and container access for the workstation and local AI workloads. |
| **PipeWire** | Audio and media infrastructure used by the desktop and its tuning in the workstation profile. |
| **WireGuard** | VPN tooling; `wg-ipv4.sh` resolves IPv4 endpoints and controls tunnel state. |
| **Flatpak** | Installs selected desktop applications outside the Nix package set. |
| **Steam, Gamescope, GameMode, Proton-GE** | Linux gaming stack, including Windows game compatibility and performance tooling. |
| **GNOME Keyring / libsecret** | Session secrets and SSH-agent integration for Hyprland. |
| **SDDM / SilentSDDM** | Wayland-capable login manager and themed greeter. |
| **Plymouth** | Boot splash and quiet boot animation. |
| **sbctl / UEFI Secure Boot** | Creates and enrolls firmware signing keys; the helper does not sign the system itself. |
| **Git** | Version control; `.gitignore` excludes secrets, caches, logs, backups, and generated data. |

The desktop applications are configured rather than implemented here. Kitty is
the terminal, Rofi is the launcher, Mako handles notifications, Clipse handles
clipboard history, Btop monitors the system, GTK files control toolkit themes,
fastfetch displays system information, and Vencord customizes Discord.

<a id="read-docker"></a>
## 🐳 Docker Compose services

Compose files are stored in `home/.docker-composers/`:

- `traefik.docker-compose.yml`: local reverse proxy.
- `ollama-nvidia.docker-compose.yml`: Ollama with NVIDIA access and related
  local AI services.

The `lazy-docker-containers.sh` script discovers Compose files in this
directory and provides an interactive start, stop, logs, and management
wrapper. Persistent application data is kept under the ignored `data/` path.
The configured local hostnames include `traefik.local.lan` and `ai.local.lan`.

<a id="read-scripts"></a>
## 🛠️ Scripts

Scripts are installed to `$HOME/.scripts/` by `setup.sh`.

| Script | Purpose |
| --- | --- |
| `home-backup.sh` | Back up the home directory to the configured host backup share |
| `hypr-animations.sh` | Animate active-window borders for OLED care |
| `hypr-live-wallpaper-fetcher.sh` | Download and optimize live wallpapers |
| `hypr-live-wallpaper.sh` | Run and rotate live wallpapers, with gaming checks |
| `hypr-powermenu.sh` | Hyprland logout, reboot, and shutdown menu |
| `hypr-service.sh` | Start Hyprland services with retries and logging |
| `hypr-toggle-hdr.sh` | Toggle HDR and SDR monitor profile files |
| `lazy-docker-containers.sh` | Manage the Compose applications interactively |
| `shutdown-confirm.sh` | Show a cancellable shutdown countdown |
| `start-hyprland-keyring.sh` | Start GNOME Keyring and launch Hyprland |
| `swayosd-wrapper.sh` | Provide volume, brightness, and media controls |
| `update-blackshard-linux.sh` | Update the BlackShark Linux package metadata |
| `update-hyprcapture.sh` | Update the HyprCapture package to a release tag |
| `update-nix-unstable.sh` | Switch the `nixos` channel to unstable and rebuild |
| `update-nvidia-drivers.sh` | Update the workstation NVIDIA driver configuration |
| `update-proton-ge.sh` | Download or update Proton-GE versions |
| `wg-ipv4.sh` | Bring a WireGuard configuration up or down using IPv4 endpoints |
| `waybar-peek.py` | Show or hide Waybar based on cursor position |

The update scripts may edit files under `/etc/nixos` or download external
artifacts. Read their usage output and review the diff before rebuilding.

## 🔐 Secure Boot

`secureboot-init.sh` is a one-time helper intended for a supported UEFI
system with `sbctl` installed:

```bash
./secureboot-init.sh
```

It creates Secure Boot keys and enrolls them with Microsoft and firmware-built
keys. It does not sign the NixOS system, verify Secure Boot state, or replace
the normal `nixos-rebuild` workflow. Confirm your firmware and `sbctl` state
before enrolling keys; this operation can affect bootability.

## 🔒 Secrets and ignored data

The real backup credentials file is intentionally ignored:

```text
etc/nixos/secrets/fs-backups-creds.env
```

Use `fs-backups-creds.env.example` as the shape of the file. Do not commit
credentials, private keys, certificates, tokens, logs, caches, editor state,
Nix build results, or Docker application data. These exclusions are maintained
in `.gitignore`; only the example secrets file is intended to be tracked.

Hardware configuration files still expose disk UUIDs, mount locations, host
names, and private infrastructure names. Review them before publishing or
reusing this repository.

<a id="fresh-install-requirements"></a>
## ✅ Fresh-install requirements

| Item | What to do before `nixos-rebuild` |
| --- | --- |
| User | Replace `ruipa` and `/home/ruipa` references, including hardware groups and Waybar paths. |
| Machine identity | Keep the target `/etc/machine-id`; replace `machine-id-salt.txt` with your own stable private salt. |
| NixOS profile | Run `./init.sh`, then replace the author's hardware, filesystem, network, GPU, hostname, and firewall settings. |
| CIFS credentials | If using the backup share, create `/etc/nixos/secrets/fs-backups-creds.env` from `fs-backups-creds.env.example` and set `username=` and `password=`. |
| Optional services | Remove unused CIFS, Docker Compose, Secure Boot, NVIDIA, and custom-app configuration before rebuilding. |

The CIFS credentials file is intentionally absent from a clean checkout and
must never be committed. Set it to mode `600`. If you do not use the backup
share, remove its `fileSystems` entry and skip `home-backup.sh`.

<a id="make-it-yours-fresh-install-cleanup"></a>
## 🧹 Make it yours: fresh-install cleanup

This repository contains personal hardware and desktop choices. For a clean
personal fork, make these changes before running `setup.sh`:

### Keep and adapt

- Keep `init.sh`, `setup.sh`, `.gitignore`, and the overall `etc/` and `home/`
  layout if you want the symlink workflow.
- Replace `etc/nixos/machine-id-salt.txt` with a new private salt. Do not reuse
  the existing machine identity scheme unless you also intend to use its
  profile directories.
- Replace `etc/nixos/users.nix`: change `ruipa`, groups, and user packages to
  your account.
- Review `etc/nixos/environment.nix`: aliases and the `confedit` path currently
  point at this repository and the included Hyprland power menu.
- Replace the profile hardware, network, filesystem, and hostname settings
  with files generated for your machine. Run `./init.sh` first so the new
  hashed profile directory exists.

### Delete or replace personal content

- Remove the existing entries under `etc/nixos/profiles/` and create your own
  profile after inspecting the generated hardware configuration. The readable
  `nb-nixyoga` and `ws-nixosx3d` entries are aliases for the author's machines.
- Remove `home/.config/hypr/hyprland.profiles.d/` profile contents that describe
  the author's monitors, input devices, environment, and startup commands.
- Remove or rewrite `home/.docker-composers/` if you do not want the Traefik or
  local AI services. Delete its `data/` directory when discarding their local
  state.
- Remove personal assets and application state under `home/.config/fastfetch/`,
  `home/.config/Vencord/`, `home/.config/opencode/`, and
  `home/.local/share/icons/` if they are not yours.
- Remove or rewrite scripts under `home/.scripts/`, especially
  `home-backup.sh`, the NVIDIA and Proton-GE updaters, wallpaper scripts,
  WireGuard helpers, and device-specific Waybar scripts.
- Remove custom applications from `etc/nixos/custom-apps/` and their package
  references in `packages.nix` if you do not use BlackShark Linux or
  HyprCapture.
- Review `extra-hosts.nix`, CIFS backup paths, disk identifiers, GPU settings,
  firewall ports, and every hostname before applying the configuration.

### Never copy into a fresh public fork

- Do not add `etc/nixos/secrets/fs-backups-creds.env`; create it locally from
  `fs-backups-creds.env.example` only when you need the backup mount.
- Do not keep old `.bak`, `.old-*`, logs, caches, editor state, Docker data,
  private keys, certificates, or tokens. `.gitignore` is designed to exclude
  most of these, but check `git status` before committing.

After cleanup, use `git grep -n 'ruipa\|nixyoga\|nixosx3d\|local.lan'` to find
remaining personal identifiers, then run `./init.sh`, `./setup.sh`, and a
reviewed `sudo nixos-rebuild switch` on the new installation.

## 🧩 Extending the repository

1. Put system modules below `etc/nixos/` and import them from
   `configuration.nix` when appropriate.
2. Put home-level files below `home/` using the target filesystem layout.
3. Put machine-only Nix and Hyprland files in the hashed profile directory
   created by `init.sh`; keep the readable symlinks for navigation.
4. Run `./setup.sh`, inspect the resulting links and backups, then run
   `sudo nixos-rebuild switch` when system configuration changed.

The repository intentionally uses plain symlinks instead of Home Manager so
the destination of every managed file is explicit and the same linking script
can be used for the user configuration independently of NixOS activation.

## ⚠️ Known limitations

- `setup.sh` has no dry-run or automated rollback mode.
- `init.sh` does not migrate hardware configuration files or configure a
  hostname.
- Profile selection depends on matching `/etc/machine-id` and
  `machine-id-salt.txt`; a new installation needs a corresponding profile
  directory before `nixos-rebuild` can succeed.
- `secureboot-init.sh` only prepares and enrolls keys; signing and state
  verification remain separate tasks.

## 🤖 AI-assisted development

I use AI as a fast pair of hands. It helps me spin up scripts, try ideas, and
add useful features without spending an afternoon on boilerplate. It does not
design the architecture of this repository: the structure, system design, and
technical decisions are mine.

AI output is only a draft. I read it, test it, fix it, and sometimes throw it
away completely before anything stays in the repo. I have a real developer
and systems administration background, so I am responsible for understanding
and maintaining what gets committed. Unknown code does not get a free pass
here.

I generally avoid using agentic AI in my other repositories. This one is a
deliberate exception: I run it on my own machines every day, so I can quickly
check the result in a real environment and fix problems as they appear. The
goal is simple: keep the system working and move quickly, without giving up
understanding or review.

In short: vibe coding is fine for brainstorming, but production gets the
review treatment. The vibes may enter; the unreviewed code may not. 🙂
