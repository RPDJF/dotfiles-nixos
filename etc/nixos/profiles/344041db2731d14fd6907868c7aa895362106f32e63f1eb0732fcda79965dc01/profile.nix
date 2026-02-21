{ config, lib, pkgs, ... }:

{
    imports = [
      ./hardware-configuration.nix
      ./network.nix
    ];

    environment.variables = {
      # nvidia config
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
}