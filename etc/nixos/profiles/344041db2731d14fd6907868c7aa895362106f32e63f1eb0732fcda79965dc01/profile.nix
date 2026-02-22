{ config, lib, pkgs, ... }:

{
    imports = [
      ./hardware-configuration.nix
      ./network.nix
    ];

    environment.variables = let
      tasksetArgs = "-a -c 0-15";
      gamescopeArgs = "-W 3840 -H 2160 -w 3840 -h 2160 --force-wayland --hdr-enabled --force-grab-cursor --adaptive-sync --rt --steam -f -r 240 --backend wayland";
    in {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      PROTON_ENABLE_NVAPI = "1";
      PROTON_HIDE_NVIDIA_GPU = "0";
      PROTON_ENABLE_WAYLAND = "1";

      TASKSET_ARGS = tasksetArgs;
      GAMESCOPE_ARGS = gamescopeArgs;
      STEAM_ARGS = "taskset ${tasksetArgs} gamescope ${gamescopeArgs} -- %command%";
    };
}