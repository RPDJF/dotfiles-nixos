{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;

  # Enable Docker support
  virtualisation.docker.enable = true;
  systemd.services.docker.wantedBy = [ ];  # removes it from auto-start

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
    unzip
    unrar
    mpv
    killall

    # System control utilities
    brightnessctl         # Laptop screen back‑light control
    pavucontrol           # Graphical mixer for PipeWire/PulseAudio
  
    # Applications
    librewolf
    ungoogled-chromium # for dev
    (discord.override {
      # withOpenASAR = true; # can do this here too
      withVencord = true;
    })
    jellyfin-desktop
    proton-vpn
    (heroic.override {
    extraPkgs = pkgs': with pkgs'; [
      gamescope
      gamemode
      ];
    })
    qbittorrent
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    })
    wireguard-tools

    # System applications
    rofi
    clipse
    font-manager
    nautilus
    wine

    # System utilities
    gnome-keyring
    libsecret
    python3
    libnotify # Notification library
    yt-dlp
    ffmpeg
    wlr-randr
    sound-theme-freedesktop

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

    # vulkan
    vulkan-tools   # Vulkan tools to verify Vulkan support
    vulkan-loader  # Vulkan runtime loader for Vulkan applications

    # libraries
    qt5.qtwayland
    libsForQt5.qtwayland
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
    libcanberra-gtk3
  ];

  # flatpaks
  services.flatpak.enable = true;
  systemd.services.install-flatpaks = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [ pkgs.flatpak ];

    script = ''
      flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo

      flatpak install -y flathub io.github.Soundux
    '';
  };

  nixpkgs.config.qt5 = {
    enable = true;
    platformTheme = "qt5ct"; 
  };

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
  programs.bash = {
    enable = true;
    completion.enable = true;
  };
  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;

  # start gnome-keyring
  services.gnome.gnome-keyring.enable = true;
}
