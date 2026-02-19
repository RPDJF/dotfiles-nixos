{ config, lib, pkgs, ... }:

{
  environment.variables.SSH_AUTH_SOCK = "/run/user/1000/gcr/ssh";
  environment.shellAliases = {
    confedit = "code $HOME/dotfiles-nixos";
  };
}