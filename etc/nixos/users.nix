{ config, lib, pkgs, ... }:

{
  users.users.ruipa = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input"];
    packages = with pkgs; [
      tree
    ];
    initialPassword = "change-me";
  };
}