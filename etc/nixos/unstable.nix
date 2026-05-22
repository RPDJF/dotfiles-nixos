{ config, pkgs, ... }:

let
  unstableTarball = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
in
{
  nixpkgs.config.packageOverrides = super: {
    unstable = import unstableTarball {
      config = config.nixpkgs.config;
      system = pkgs.system;
    };
  };
}