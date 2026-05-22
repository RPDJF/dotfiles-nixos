{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
  ];
  
  environment.variables =   {
    __VK_LAYER_NV_optimus = "NVIDIA_only";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    PROTON_ENABLE_NVAPI = "1";
    PROTON_HIDE_NVIDIA_GPU = "0";
    PROTON_ENABLE_WAYLAND = "1";
    DXVK_HDR = "1";
    PROTON_ENABLE_HDR = "1";
    ENABLE_HDR_WSI = "1";
    PROTON_USE_NTSYNC = "1";
    SteamDeck = "0";
    TASKSET_ARGS = "-a -c 0-15";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    NVD_BACKEND = "direct";
  };

  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
    libva
    libva-utils
    davinci-resolve # video editing software
  ];
}