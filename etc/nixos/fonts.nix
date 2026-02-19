{ config, lib, pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  fonts.fonts = with pkgs; [
    font-awesome
    material-icons
    powerline-fonts
    powerline-symbols
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-sans-static
    noto-fonts-cjk-serif
    noto-fonts-cjk-serif-static
    noto-fonts-color-emoji
  ]
  ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts)
  ;
}