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
    #aseprite # disabled because current compiler doesn't support it
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
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    })
    wireguard-tools
    opencode

    # System applications
    rofi
    clipse
    font-manager
    nautilus

    # System utilities
    gnome-keyring
    libsecret
    python3
    libnotify # Notification library
    yt-dlp
    ffmpeg
    wlr-randr
    sound-theme-freedesktop
    cifs-utils

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
    # opengl libraries (for games and other 3D applications)
    stdenv.cc.cc
    zlib
    glib
    libGL
    vulkan-loader
    libx11
    libxext
    libxrandr
    libxrender
    libxcursor
    libxi
    libxfixes
    libxinerama

    p7zip
    cabextract
    zenity
    gdk-pixbuf

    gtk3
    gtk4
    adwaita-icon-theme
    hicolor-icon-theme
    shared-mime-info
    librsvg
    freetype
    fontconfig
    cairo
    pango
    wineWow64Packages.stable
    winetricks
  ];

  # flatpaks
  services.flatpak.enable = true;
  systemd.services.install-flatpaks = {
    description = "Install Flatpaks";

    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "systemd-resolved.service"
      ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [
      pkgs.flatpak
      pkgs.curl
      pkgs.coreutils
    ];

    script = ''
      set -euo pipefail

      FLATHUB_APPS=(
        "io.github.Soundux"
        "com.dec05eba.gpu_screen_recorder"
      )

      DIRECT_URLS=(
        "https://github.com/Recol/DLSS-Updater/releases/download/V4.1.8/DLSS_Updater-4.1.8.flatpak"
      )

      flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo || true

      for app_id in "''${FLATHUB_APPS[@]}"; do
        if ! flatpak install --noninteractive -y --system flathub "$app_id"; then
          echo "Warning: Failed to install $app_id" >&2
        fi
      done

      for url in "''${DIRECT_URLS[@]}"; do
        tmp=$(mktemp -d)

        if ! curl --fail -L -o "$tmp/app.flatpak" "$url"; then
          echo "Warning: Failed to download $url" >&2
        elif ! flatpak install --noninteractive -y --system --reinstall "$tmp/app.flatpak"; then
          echo "Warning: Failed to install flatpak from $url" >&2
        fi

        rm -rf "$tmp"
      done
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
  services.cron.enable = true;

  xdg.mime.defaultApplications = {
    "x-scheme-handler/http" = "librewolf.desktop";
    "x-scheme-handler/https" = "librewolf.desktop";
    "text/html" = "librewolf.desktop";
  };

  # start gnome-keyring
  services.gnome.gnome-keyring.enable = true;
}
