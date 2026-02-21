{ config, lib, pkgs, ... }:

{
  environment.variables.SSH_AUTH_SOCK = "/run/user/1000/gcr/ssh";
  environment.variables.LANG = "fr_CH.UTF-8";
  environment.shellAliases = {
    confedit = "code $HOME/dotfiles-nixos";
    clear = "clear && printf \"\\e[3J\"";
  };
}