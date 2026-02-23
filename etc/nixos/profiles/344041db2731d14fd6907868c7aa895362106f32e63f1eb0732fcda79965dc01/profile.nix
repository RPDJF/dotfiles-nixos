{ config, lib, pkgs, ... }:

{
    imports = [
      ./hardware-configuration.nix
      ./network.nix
    ];

    environment.variables =   {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      PROTON_ENABLE_NVAPI = "1";
      PROTON_HIDE_NVIDIA_GPU = "0";
      PROTON_ENABLE_WAYLAND = "1";
      DXVK_HDR = "1";
      PROTON_ENABLE_HDR = "1";
      ENABLE_HDR_WSI = "1";
      PROTON_USE_NTSYNC = "1";
      SteamDeck = "0";
      TASKSET_ARGS = "-a -c 0-15";
    };
}