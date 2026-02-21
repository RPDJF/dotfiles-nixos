{ config, lib, pkgs, ... }:

{
  environment.variables = {
    SSH_AUTH_SOCK = "/run/user/1000/gcr/ssh";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };
  environment.shellAliases = {
    confedit = "code $HOME/dotfiles-nixos";
    clear = "clear && printf \"\\e[3J\"";
  };
}