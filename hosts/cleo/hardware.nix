{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/238f6eb4-b155-499e-b75a-2f1d233797ed";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0F59-178A";
    fsType = "vfat";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/3c6e053d-68ca-423e-8ff8-184dab3eab02";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/e02f5046-315f-4f6e-a748-a843336fabf2"; } ];

  boot = {
    kernelPackages = pkgs.linuxPackages;
    initrd = {
      availableKernelModules = [
        "ahci"
        "rtsx_pci_sdmmc"
        "sd_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
      kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
    };
    extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
    kernelModules = [
      "acpi_call"
      "kvm_intel"
    ];
    kernelParams = [
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    kernel.sysctl = {
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Refuse ICMP echo requests
    };
  };

  nix.settings.max-jobs = mkDefault 4;
  hardware = {
    cpu.intel.updateMicrocode = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver    # Intel iGPU VA-API (for offloaded video decode)
      ];
    };

    nvidia = {
      modesetting.enable = true;
      # Nvidia power management. Required for suspend/resume to work reliably with PreserveVideoMemoryAllocations.
      powerManagement.enable = true;
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = true;

      # Keep NVIDIA kernel module state loaded for faster GPU wake from power-off.
      nvidiaPersistenced = true;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      # Do not disable this unless your GPU is unsupported or if you have a good reason to.
      open = true;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.production;
      # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #   version = "570.86.16"; # use new 570 drivers
      #   sha256_64bit = "sha256-RWPqS7ZUJH9JEAWlfHLGdqrNlavhaR1xMyzs8lJhy9U=";
      #   openSha256 = "sha256-DuVNA63+pJ8IB7Tw2gM4HbwlOh1bcDg2AN2mbEU9VPE=";
      #   settingsSha256 = "sha256-9rtqh64TyhDF5fFAYiWl3oDHzKJqyOW3abpcf2iNRT8=";
      #   usePersistenced = false;
      # };
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        # Make sure to use the correct Bus ID values for your system!
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  powerManagement.cpuFreqGovernor = mkDefault "schedutil";

  # Manage device power-control:
  services = {
    upower.enable = true;
    # power-profiles-daemon.enable = true;
    # tuned.enable = true;
    thermald.enable = true;
    auto-cpufreq.enable = lib.mkForce false;
    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
        RESTORE_THRESHOLDS_ON_BAT = 1;

        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        PCIE_ASPM_ON_AC = "performance";
        PCIE_ASPM_ON_BAT = "powersave";

        # Prevents bluez from hanging:
        USB_DENYLIST = "8087:0029";
      };
    };
    xserver = {
      videoDrivers = [ "nvidia" ];
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

  # Finally, our beloved hardware module(s):
  modules.hardware = {
    nvidia = {
      enable = true;
      cuda.enable = false;
    };
    pipewire = {
      enable = true;
      # lowLatency.enable = true;
    };
    bluetooth.enable = true;
    kmonad.deviceID = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
    pointer.enable = true;
    printer.enable = true;
    razer.enable = false;
  };
}
