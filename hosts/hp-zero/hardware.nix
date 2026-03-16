{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (lib) mkDefault;
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-GO
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@log"
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

  fileSystems."/swap" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@swap"
      "noatime"
    ];
  };

  swapDevices = [ { device = "/swap/swapfile"; } ];

  boot = {
    kernelPackages = pkgs.linuxPackages;
    initrd = {
      availableKernelModules = [
        "nvme"
        "vmd"
        "ahci"
        "rtsx_pci_sdmmc"
        "sd_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
        "btrfs"
      ];
      kernelModules = [ ];
      luks.devices."cryptroot" = {
        device = "/dev/nvme0n1p2";
        preLVM = true; # Not strictly needed for Btrfs but good practice
        allowDiscards = true; # Better for SSD performance
      };
    };
    extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
    kernelModules = [
      "acpi_call"
      "kvm_intel"
    ];
    resumeDevice = "/dev/mapper/cryptroot";
    # NOTE: You must update the resume_offset after creating the swapfile.
    # Run: btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile
    # Then add "resume_offset=XXXXX" to kernelParams below.
    kernelParams = lib.mkAfter [
      # pcie_aspm.policy=performance is already set in default.nix for all hosts
      "i915.enable_guc=3"
      "resume_offset=533760" # REPLACE with output from 'btrfs inspect-internal map-swapfile'
      "mem_sleep_default=s2idle" # Use s2idle for S0ix support with NVIDIA open driver
      "nvidia.NVreg_EnableS0ixPowerManagement=1" # Enable S0ix power management (NVIDIA 570+)
      # Override NixOS nvidia module's PreserveVideoMemoryAllocations=1:
      # powerManagement.enable injects =1, but S0ix self-refresh handles VRAM natively;
      # the preserve path triggers open-driver bug #472. Kernel uses LAST cmdline value.
      "nvidia.NVreg_PreserveVideoMemoryAllocations=0"
    ];
    kernel.sysctl = {
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Refuse ICMP echo requests
    };
  };

  nix.settings.max-jobs = mkDefault 4;
  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # For TigerLake+
        vpl-gpu-rt # Successor of oneVPL-intel-gpu
        libva-utils
      ];
    };

    nvidia = {
      modesetting.enable = true;
      # Nvidia power management. Creates nvidia-suspend/hibernate/resume systemd services.
      # Note: this also injects NVreg_PreserveVideoMemoryAllocations=1, which we override
      # to =0 in kernelParams (S0ix self-refresh handles VRAM instead).
      powerManagement.enable = true;
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

  # cpuFreqGovernor removed — TLP manages governors via CPU_SCALING_GOVERNOR_ON_AC/BAT.
  # Setting "schedutil" here caused a 2.6s boot delay (nixpkgs#204619: schedutil is built
  # into the kernel as CONFIG_CPU_FREQ_GOV_SCHEDUTIL=y, not a loadable module).
  environment.variables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
  environment.systemPackages = [ nvidia-offload ];

  # NVIDIA suspend-then-hibernate support:
  #
  # NixOS wires nvidia-suspend/hibernate/resume to systemd-suspend.service and
  # systemd-hibernate.service, but NOT to systemd-suspend-then-hibernate.service.
  #
  # Strategy (S0ix + NVIDIA's own system-sleep hook):
  # - nvidia-suspend.service: Before= wiring handles the initial suspend prep
  # - NVIDIA's system-sleep/nvidia hook: handles mid-cycle transitions (hibernate
  #   phase, suspend-after-failed-hibernate) via lightweight procfs writes
  # - nvidia-resume.service: After= wiring handles the final VT switch/restore
  #   when the entire suspend-then-hibernate cycle completes
  #
  # The hook intentionally does NOT do VT switch on mid-cycle resume (post:*),
  # only writes "resume" to /proc/driver/nvidia/suspend. This avoids switching
  # back to Xorg between the suspend→hibernate transition. The full nvidia-sleep.sh
  # resume (with VT switch) runs via nvidia-resume.service at cycle end.
  systemd.services.nvidia-suspend.requiredBy = [ "systemd-suspend-then-hibernate.service" ];
  systemd.services.nvidia-suspend.before = [ "systemd-suspend-then-hibernate.service" ];
  systemd.services.nvidia-resume.requiredBy = [ "systemd-suspend-then-hibernate.service" ];
  systemd.services.nvidia-resume.after = [ "systemd-suspend-then-hibernate.service" ];

  # Deploy NVIDIA's own system-sleep hook from the driver package.
  # NixOS's systemd.packages only picks up .service/.timer units, not system-sleep hooks.
  # This hook handles suspend-then-hibernate mid-cycle transitions (hibernate prep,
  # suspend-after-failed-hibernate, lightweight procfs resume) without VT switching.
  # For plain suspend/hibernate, it calls the full nvidia-sleep.sh resume.
  environment.etc."systemd/system-sleep/nvidia" = {
    source = "${config.hardware.nvidia.package}/lib/systemd/system-sleep/nvidia";
    mode = "0755";
  };

  # systemd 256+ freezes user sessions BEFORE nvidia-sleep.sh can write to
  # /proc/driver/nvidia/suspend, breaking NVIDIA's suspend preparation.
  # All major distros (Arch, Debian, Gentoo, openSUSE) ship this workaround.
  # See: https://github.com/NVIDIA/open-gpu-kernel-modules/issues/834
  systemd.services.systemd-suspend.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
  systemd.services.systemd-hibernate.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
  systemd.services.systemd-suspend-then-hibernate.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";

  # Restore networking after suspend/hibernate resume:
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

  # Manage device power-control:
  services = {
    fwupd.enable = true;
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
