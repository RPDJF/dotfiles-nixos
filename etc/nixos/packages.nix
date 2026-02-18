{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Development tools
    alacritty             # GPU‑accelerated terminal
    git                   # Version control
    vim                   # Classic editor
    vscode                # Visual Studio Code (GUI)
    fastfetch             # Compact system‑information summary
  
    # System control utilities
    brightnessctl         # Laptop screen back‑light control
    pavucontrol           # Graphical mixer for PipeWire/PulseAudio
  
    # Applications
    librewolf
    dorion                # Discord client
    jellyfin-desktop
    protonvpn-gui
    steam

    # System applications
    rofi
    waybar
    hyprshot
    clipse
    hyprlock
    hypridle
    hyprpaper
    font-manager
    hyprpolkitagent

    # native‑Wayland helpers
    pamixer               # Simple PulseAudio/pipewire‑pulse volume control
    playerctl             # MPRIS media‑player control (play/pause/next/prev)
    mako                  # Wayland‑native notification daemon
    networkmanager
    networkmanagerapplet  # Optional tray icon for NM
    wl-clipboard          # Wayland clipboard utilities (wl‑copy / wl‑paste)
    upower                # DBus power service (battery status for Waybar)
    acpi                  # CLI for battery / thermal information
    swayosd               # OSD app

    # themes
    catppuccin-gtk
    papirus-icon-theme
    nwg-look
  ];
}