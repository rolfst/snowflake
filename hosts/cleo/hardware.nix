{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  inherit (lib) mkDefault;
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-GO
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

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

  swapDevices = [{device = "/dev/disk/by-uuid/e02f5046-315f-4f6e-a748-a843336fabf2";}];

  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "rtsx_pci_sdmmc"
        "sd_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
      kernelModules = [];
    };
    extraModulePackages = [config.boot.kernelPackages.acpi_call];
    kernelModules = ["acpi_call" "kvm_intel"];
    kernelParams = ["pcie_aspm.policy=performance"];
    kernel.sysctl = {
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Refuse ICMP echo requests
    };
  };

  nix.settings.max-jobs = mkDefault 4;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Do not disable this unless your GPU is unsupported or if you have a good reason to.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    prime = {
      offload.enable = true;
      # Make sure to use the correct Bus ID values for your system!
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  powerManagement.cpuFreqGovernor = mkDefault "schedutil";
  environment.systemPackages = [nvidia-offload];

  # Manage device power-control:
  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
    thermald.enable = true;
    xserver = {
      videoDrivers = ["nvidia"];
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

  # Finally, our beloved hardware module(s):
  modules.hardware = {
    pipewire = {
      enable = true;
      # lowLatency.enable = true;
    };
    bluetooth.enable = true;
    # kmonad.deviceID = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
    pointer.enable = true;
    printer.enable = true;
    razer.enable = true;
  };
}
