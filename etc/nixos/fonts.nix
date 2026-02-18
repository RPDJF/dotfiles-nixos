{ config, lib, pkgs, ... }:

{
  fonts.fontconfig.enable = true;
  fonts.fonts = with pkgs; [
    font-awesome
    material-icons
    powerline-fonts
    powerline-symbols
  ]
  ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}