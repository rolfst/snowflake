{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  inherit (lib) mkDefault;
in {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = ["noatime" "x-gvfs-hide"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["x-gvfs-hide"];
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "sr_mod"
      ];
      kernelModules = [];
    };
    extraModulePackages = [];
    kernelModules = ["kvm-intel:"];
    kernelParams = [];
  };

  nix.settings.max-jobs = mkDefault 4;

  hardware.cpu.amd = {
    updateMicrocode = true;
    # updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
  };

  powerManagement.cpuFreqGovernor = mkDefault "schedutil";

  # Manage device power-control:
  services = {
    power-profiles-daemon.enable = true;
    thermald.enable = true;
  };

  # Finally, our beloved hardware module(s):
  modules.hardware = {
    pipewire.enable = true;
    bluetooth.enable = false;
    # kmonad.deviceID = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
    pointer.enable = true;
    printer.enable = true;
    razer.enable = true;
  };

  services = {
    upower.enable = true;
    xserver = {
      videoDrivers = [];
      deviceSection = ''
        Option "TearFree" "true"
      '';
      libinput = {
        enable = true;
        touchpad = {
          accelSpeed = "0.5";
          accelProfile = "adaptive";
          disableWhileTyping = true;
          naturalScrolling = true;
          scrollMethod = "twofinger";
          tapping = true;
        };
      };
    };
  };
}
