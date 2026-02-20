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
      ./profiles/${hashedId}/profile.nix
      ./environment.nix
      ./packages.nix
      ./locale.nix
      ./desktop-manager.nix
      ./users.nix
      ./fonts.nix
      ./boot-animation.nix
    ];

  system.stateVersion = "25.11";

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
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
