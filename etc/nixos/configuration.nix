{ config, lib, pkgs, ... }:

let
  rawId   = builtins.readFile "/etc/machine-id";
  cleanId = lib.strings.removeSuffix "\n" rawId;

  saltPath = "/etc/nixos/machine-id-salt.txt";
  rawSalt = builtins.tryEval (builtins.readFile saltPath);
  salt    = if rawSalt.success
            then lib.strings.removeSuffix "\n" rawSalt.value
            else "";

  hashedId = builtins.hashString "sha256" (salt + cleanId);
  profileDir = "./profiles/${hashedId}";
in
{
  imports =
    [
      ./profiles/${hashedId}/profile.nix
      ./environment.nix
      ./packages.nix
      ./locale.nix
      ./desktop-manager.nix
      ./users.nix
      ./fonts.nix
      ./boot-animation.nix
      ./extra-hosts.nix
    ];

  system.stateVersion = "25.11";

  boot.loader.grub.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.limine.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  security.polkit.enable = true; #for vscode

  # Automatically install system updates daily
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "11:00"; # UTC = 4am PDT / 3am PST
  };

  # Run garbage collection on a weekly basis to avoid filling up disk
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # because 7.1.2-zen1 breaks
  # boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage (
  #   { lib, stdenv, fetchFromGitHub, buildLinux, ... }@args:
  #   let
  #     mkKernelOverride = lib.mkOverride 90;
  #     suffix = "zen1";
  #     version = "7.0.12";
  #   in
  #   buildLinux (args // rec {
  #     inherit version;
  #     pname = "linux-zen";
  #     modDirVersion = lib.versions.pad 3 "${version}-${suffix}";
  #     isZen = true;
  #     src = fetchFromGitHub {
  #       owner = "zen-kernel";
  #       repo = "zen-kernel";
  #       rev = "v${version}-${suffix}";
  #       sha256 = "02fkkmmc28rw0kg02807jvv6k745zqfb9wg65dfd8sl298krp0fp";
  #     };
  #     structuredExtraConfig = with lib.kernel; {
  #       ZEN_INTERACTIVE = yes;
  #       NET_SCH_DEFAULT = yes;
  #       DEFAULT_FQ_CODEL = yes;
  #       PREEMPT = mkKernelOverride yes;
  #       PREEMPT_LAZY = mkKernelOverride no;
  #       TREE_RCU = yes;
  #       PREEMPT_RCU = yes;
  #       RCU_EXPERT = yes;
  #       TREE_SRCU = yes;
  #       TASKS_RCU_GENERIC = yes;
  #       TASKS_RCU = yes;
  #       TASKS_RUDE_RCU = yes;
  #       TASKS_TRACE_RCU = yes;
  #       RCU_STALL_COMMON = yes;
  #       RCU_NEED_SEGCBLIST = yes;
  #       RCU_FANOUT = freeform "64";
  #       RCU_FANOUT_LEAF = freeform "16";
  #       RCU_BOOST = yes;
  #       RCU_BOOST_DELAY = option (freeform "500");
  #       RCU_NOCB_CPU = yes;
  #       RCU_LAZY = yes;
  #       RCU_DOUBLE_CHECK_CB_TIME = yes;
  #       IOSCHED_BFQ = mkKernelOverride yes;
  #       FUTEX = yes;
  #       FUTEX_PI = yes;
  #       NTSYNC = yes;
  #       HZ = freeform "1000";
  #       HZ_1000 = yes;
  #     };
  #     extraMeta = {
  #       branch = lib.versions.majorMinor version + "/master";
  #       description = "Built using the best configuration and kernel sources for desktop, multimedia, and gaming workloads.";
  #       broken = stdenv.hostPlatform.isAarch64;
  #     };
  #   })
  # ) {});
   
  programs.direnv.enable = true;
}
