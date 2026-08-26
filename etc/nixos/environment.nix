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
  };
}