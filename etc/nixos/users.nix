{ config, lib, pkgs, ... }:

{
  users.users.ruipa = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "docker"];
    packages = with pkgs; [
      tree
    ];
  };
}