{ config, lib, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };
  services.xserver.displayManager.sessionCommands = ''
    export GTK_THEME=Catppuccin-Mocha
    export XCURSOR_THEME=Bibata-Modern-Ice
    export XCURSOR_SIZE=24
  '';
  services.libinput.enable = true;
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd hyprland";
        user = "greeter";
      };
    };
  };
}