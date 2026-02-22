{ config, lib, pkgs, ... }:

{
    imports = [
      ./hardware-configuration.nix
      ./network.nix
    ];

    environment.variables = {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      PROTON_ENABLE_NVAPI="1";
      PROTON_HIDE_NVIDIA_GPU="0";
      PROTON_ENABLE_WAYLAND="1";
    };
}