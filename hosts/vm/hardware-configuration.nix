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
  powerManagement.powertop.enable.true;
  powerManagement.enable = true;

  # Manage device power-control:
  services = {
    power-profiles-daemon.enable = false;
    tlp = {
        enable = true;
        settings = {
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "powersave";
            CPU_DRIVER_OPMODE_ON_AC = "active";
            CPU_DRIVER_OPMODE_ON_BAT = "active";

            RUNTIME_PM_ON_AC = "auto";
            RUNTIME_PM_ON_BAT = "auto";

            CPU_MIN_PERF_ON_AC = "0";
            CPU_MIN_PERF_ON_BAT = "0";
            CPU_MAX_PERF_ON_AC = "100";
            CPU_MAX_PERF_ON_BAT = "50";

            CPU_BOOST_ON_AC = "1";
            CPU_BOOST_ON_BAT = "0";

            MEM_SLEEP_ON_AC = "deep";
            MEM_SLEEP_ON_BAT = "deep";

            PLATFORM_PROFILE_ON_AC = "performance";
            PLATFORM_PROFILE_ON_BAT = "low-power";

            NMI_WATCHDOG = 0;
            RESTORE_DEVICE_STATE_ON_STARTUP = "1";

            # Optional helps with battery longevity:
            START_CHARGE_THRESH_BAT0 = "40";
            STOP_CHARGE_THRESH_BAT0 = "80";

        }
    }
    thermald.enable = true;
  };

  # Finally, our beloved hardware module(s):
  modules.hardware = {
    pipewire.enable = true;
    bluetooth.enable = false;
    kmonad.deviceID = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
    pointer.enable = true;
    printer.enable = true;
    razer.enable = true;
  };

  services = {
    upower.enable = true;
    xserver = {
      videoDrivers = ["nvidia" "displayLink" "modeSetting"];
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
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
}
