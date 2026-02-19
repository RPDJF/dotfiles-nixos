{ config, lib, pkgs, ... }:

let
  rawId   = builtins.readFile "/etc/machine-id";
  cleanId = lib.strings.removeSuffix "\n" rawId;

  saltPath = "/etc/nixos/machine-id-salt.txt";
  rawSalt = builtins.tryEval (builtins.readFile saltPath);
  salt    = if rawSalt.success
            then lib.strings.removeSuffix "\n" rawSalt.value
            else "";

  hashedId = builtins.hashString "sha256" (salt + cleanId);
  profileDir = "./profiles/${hashedId}";
in
{
  imports =
    [
      ./profiles/${hashedId}/hardware-configuration.nix
      ./profiles/${hashedId}/network.nix
      ./environment.nix
      ./packages.nix
      ./locale.nix
      ./desktop-manager.nix
      ./users.nix
      ./fonts.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
  
  security.polkit.enable = true; #for vscode

  # Automatically install system updates daily
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "11:00"; # UTC = 4am PDT / 3am PST
  };

  # Run garbage collection on a weekly basis to avoid filling up disk
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
