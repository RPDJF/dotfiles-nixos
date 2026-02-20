{ config, lib, pkgs, ... }:

{
    imports = [
      ./hardware-configuration.nix
      ./network.nix
    ];
}