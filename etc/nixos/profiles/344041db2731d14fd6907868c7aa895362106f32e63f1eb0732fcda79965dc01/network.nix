{ config, lib, pkgs, ... }:

{
  networking.hostName = "ws-nixosx3d";

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowPing = true;

  networking.firewall.allowedTCPPorts = [
    # steam remote play
    27036
    27037
    10400
  ];

  networking.firewall.allowedUDPPorts = [
    # steam remote play
    27031
    27036
    10400
    10401

  ];

  networking.firewall.checkReversePath = false;
}