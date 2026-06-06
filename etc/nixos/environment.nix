{ config, lib, pkgs, ... }:

{
  environment.variables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    OZONE_PLATFORM = "wayland";
  };
  environment.shellAliases = {
    confedit = "code $HOME/dotfiles-nixos";
    clear = "clear && printf \"\\e[3J\"";
  };
}