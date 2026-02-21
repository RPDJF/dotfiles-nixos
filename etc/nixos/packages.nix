{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    # Secure Boot utilities
    sbctl
  
    # Development tools
    kitty
    git                   # Version control
    vim                   # Classic editor
    vscode                # Visual Studio Code (GUI)
    fastfetch             # Compact system‑information summary
    openssl               # TLS/SSL library (for development and other tools that need it)
    bc                    # Arbitrary‑precision calculator (used in some scripts)
    btop
  
    # System control utilities
    brightnessctl         # Laptop screen back‑light control
    pavucontrol           # Graphical mixer for PipeWire/PulseAudio
  
    # Applications
    librewolf
    (discord.override {
      # withOpenASAR = true; # can do this here too
      withVencord = true;
    })
    jellyfin-desktop
    protonvpn-gui
    steam
    (heroic.override {
    extraPkgs = pkgs': with pkgs'; [
      gamescope
      gamemode
      ];
    })
    qbittorrent

    # System applications
    rofi
    clipse
    font-manager

    # System utilities
    gnome-keyring
    libsecret
    python3
    libnotify # Notification library

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

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  # start gnome-keyring
  services.gnome.gnome-keyring.enable = true;
}