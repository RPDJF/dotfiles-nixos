{ config, lib, pkgs, ... }:

{
  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "fr_CH";

  # Enable the X11 windowing system.
  services.xserver.xkb.layout = "ch";
  services.xserver.xkb.variant = "fr";
}