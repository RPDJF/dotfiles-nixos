{ config, lib, pkgs, ... }:

{
  networking.hostName = "nb-nixyoga";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowPing = true;
  networking.firewall.allowedTCPPorts = [];          # No incoming TCP ports allowed
  networking.firewall.allowedUDPPorts = [];          # No incoming UDP ports allowed
  networking.firewall.checkReversePath = false;
}