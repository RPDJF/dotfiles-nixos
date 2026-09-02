{ config, lib, pkgs, ... }:

let
  # SilentSDDM
  silentSDDMSrc = pkgs.fetchFromGitHub {
    owner = "uiriansan";
    repo = "SilentSDDM";
    rev = "v1.5.0";

    # First build will tell you the correct hash.
    # Replace lib.fakeHash with the resulting hash.
    hash = "sha256-HrEWOam4aMPijxcS2h+e9NZ5GE6dte7tFJzkEPQH11c=";
  };

  silentSDDM = pkgs.callPackage "${silentSDDMSrc}/nix/package.nix" {
    theme = "ken";
  };

in
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    HYPRLAND_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";

    # used in ./home/.config/hypr/loadHyprlandPlugins.sh to find plugins installed by nix; will search for libraries with names like libhypr*.so
    HYPRPLUGIN_DIR = "/run/current-system/sw/lib";
    
  };

  environment.systemPackages = with pkgs; [
    waybar
    hyprlock
    hypridle
    mpvpaper
    hyprpolkitagent

    # SilentSDDM
    silentSDDM
  ] ++ (with pkgs.hyprlandPlugins; [
    # hyprbars
  ]);

  services.libinput.enable = true;
  services.displayManager.defaultSession = "hyprland-uwsm";
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "silent";
    extraPackages = silentSDDM.propagatedBuildInputs;
    settings = {
      General = {
        InputMethod = "qtvirtualkeyboard";
        GreeterEnvironment =
          "QML2_IMPORT_PATH=${silentSDDM}/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard";
      };
    };
  };

  security.pam.services.sddm.enableGnomeKeyring = true;
}