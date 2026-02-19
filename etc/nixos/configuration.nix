{ config, lib, pkgs, ... }:

let
  rawId = builtins.readFile "/etc/machine-id";
  machineId = lib.strings.removeSuffix "\n" rawId;
in
{
  imports =
    [
      ./profiles/${machineId}/hardware-configuration.nix
      ./profiles/${machineId}/network.nix
      ./environment.nix
      ./packages.nix
      ./locale.nix
      ./desktop-manager.nix
      ./users.nix
      ./fonts.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
  
  security.polkit.enable = true; #for vscode
}
