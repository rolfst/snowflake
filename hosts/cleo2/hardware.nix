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

  # --- Filesystem layout ---
  # Two SSDs, each with its own LUKS volume, btrfs inside.
  #   sdb (250GB) = system:  /boot (EFI), cryptsystem -> @root, @nix
  #   sda (500GB) = data:    cryptdata -> @home, @var, @swap

  # == sdb: system disk (LUKS "cryptsystem") ==
  fileSystems."/" = {
    device = "/dev/mapper/cryptsystem";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptsystem";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # == sda: data disk (LUKS "cryptdata") ==
  fileSystems."/home" = {
    device = "/dev/mapper/cryptdata";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/var" = {
    device = "/dev/mapper/cryptdata";
    fsType = "btrfs";
    options = [
      "subvol=@var"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/swap" = {
    device = "/dev/mapper/cryptdata";
    fsType = "btrfs";
    options = [
      "subvol=@swap"
      "noatime"
    ];
  };

  swapDevices = [ { device = "/swap/swapfile"; } ];

  # --- Boot & LUKS ---
  boot = {
    kernelPackages = pkgs.linuxPackages;
    initrd = {
      availableKernelModules = [
        "ahci"
        "btrfs"
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

      # Primary LUKS volume — unlocked by passphrase at boot
      luks.devices."cryptsystem" = {
        device = "/dev/disk/by-label/cryptsystem";
        preLVM = true;
        allowDiscards = true; # SSD performance
      };

      # Secondary LUKS volume — auto-unlocked via keyfile stored in initrd
      luks.devices."cryptdata" = {
        device = "/dev/disk/by-label/cryptdata";
        preLVM = true;
        allowDiscards = true;
        keyFile = "/etc/secrets/cryptdata.key";
      };
    };
    extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
    kernelModules = [
      "acpi_call"
      "kvm_intel"
    ];

    # Hibernate resume: swapfile lives on cryptdata
    resumeDevice = "/dev/mapper/cryptdata";
    # NOTE: After creating the swapfile, get the offset:
    #   btrfs inspect-internal map-swapfile -r /swap/swapfile
    # Then replace the value below.
    kernelParams = lib.mkAfter [
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "resume_offset=REPLACE_ME" # REPLACE with output from btrfs inspect-internal map-swapfile
    ];
    kernel.sysctl = {
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    };
  };

  nix.settings.max-jobs = mkDefault 4;
  hardware = {
    cpu.intel.updateMicrocode = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
      ];
    };

    nvidia = {
      modesetting.enable = true;
      # Nvidia power management. Creates nvidia-suspend/hibernate/resume systemd services.
      powerManagement.enable = true;
      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = true;

      # Keep NVIDIA kernel module state loaded for faster GPU wake from power-off.
      nvidiaPersistenced = true;

      # Use the NVidia open source kernel module.
      open = true;

      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.production;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  powerManagement.cpuFreqGovernor = mkDefault "schedutil";

  # --- NVIDIA suspend-then-hibernate support ---
  #
  # NixOS wires nvidia-suspend/hibernate/resume to systemd-suspend.service and
  # systemd-hibernate.service, but NOT to systemd-suspend-then-hibernate.service.
  #
  # Strategy: nvidia-suspend handles initial suspend prep, NVIDIA's system-sleep hook
  # handles mid-cycle transitions, nvidia-resume handles final restore.
  systemd.services.nvidia-suspend.requiredBy = [ "systemd-suspend-then-hibernate.service" ];
  systemd.services.nvidia-suspend.before = [ "systemd-suspend-then-hibernate.service" ];
  systemd.services.nvidia-resume.requiredBy = [ "systemd-suspend-then-hibernate.service" ];
  systemd.services.nvidia-resume.after = [ "systemd-suspend-then-hibernate.service" ];

  # Deploy NVIDIA's system-sleep hook from the driver package.
  # Handles suspend-then-hibernate mid-cycle transitions without VT switching.
  environment.etc."systemd/system-sleep/nvidia" = {
    source = "${config.hardware.nvidia.package}/lib/systemd/system-sleep/nvidia";
    mode = "0755";
  };

  # systemd 256+ freezes user sessions BEFORE nvidia-sleep.sh can write to
  # /proc/driver/nvidia/suspend, breaking NVIDIA's suspend preparation.
  # See: https://github.com/NVIDIA/open-gpu-kernel-modules/issues/834
  systemd.services.systemd-suspend.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
  systemd.services.systemd-hibernate.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
  systemd.services.systemd-suspend-then-hibernate.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";

  # Restore networking after suspend/hibernate resume
  systemd.services.networkmanager-resume = {
    description = "Restart NetworkManager on resume";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.util-linux}/bin/rfkill unblock all
      sleep 2
      ${pkgs.systemd}/bin/systemctl try-restart NetworkManager
    '';
  };

  # --- Power & device management ---
  services = {
    upower.enable = true;
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

  # --- Hardware modules ---
  modules.hardware = {
    nvidia = {
      enable = true;
      cuda.enable = false;
    };
    pipewire = {
      enable = true;
    };
    bluetooth.enable = true;
    kmonad.deviceID = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
    pointer.enable = true;
    printer.enable = true;
    razer.enable = false;
  };
}
