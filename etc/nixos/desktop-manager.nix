{ config, lib, pkgs, ... }:

{  
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";

    # used in ./home/.config/hypr/loadHyprlandPlugins.sh to find plugins installed by nix; will search for libraries with names like libhypr*.so
    HYPRPLUGIN_DIR = "/run/current-system/sw/lib";
    
  };

  environment.systemPackages = with pkgs; [
    # additional hyprland-related packages
    waybar
    hyprshot
    hyprlock
    hypridle
    hyprpaper
    hyprpolkitagent
  ] ++ (with pkgs.hyprlandPlugins; [
    # hyprplugins
    hyprbars
  ]);

  services.libinput.enable = true;
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd hyprland";
        user = "greeter";
      };
    };
  };
}