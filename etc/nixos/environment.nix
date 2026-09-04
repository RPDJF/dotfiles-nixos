{ config, lib, pkgs, ... }:

{
  environment.variables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    OZONE_PLATFORM = "wayland";
    NIXPKGS_ALLOW_UNFREE = "1";
  };
  environment.shellAliases = {
    confedit = "code $HOME/dotfiles-nixos";
    clear = "clear && printf \"\\e[3J\"";
    reboot = "nohup hypr-powermenu.sh restart >/dev/null 2>&1 &";
    shutdown = "nohup hypr-powermenu.sh shutdown >/dev/null 2>&1 &";
    logout = "nohup hypr-powermenu.sh logout >/dev/null 2>&1 &";
  };
}