{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/nvme0n1p2";
    preLVM = true;
  };
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  fileSystems."/" =
    { device = "/dev/mapper/vg0-root";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C41E-FB8B";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices =
    [ { device = "/dev/mapper/vg0-swap"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
