{ options, config, lib, pkgs, ... }:

let inherit (lib.modules) mkIf;
in {
  options.modules.containers.archlinux =
    let inherit (lib.options) mkEnableOption;
    in { enable = mkEnableOption "arch-linux container"; };

  config = mkIf config.modules.containers.archlinux.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemuVerbatimConfig = ''
        user = "rolfst"
      '';
    };

    systemd.nspawn."archLinux" = {
      enable = true;
      wantedBy = [ "machines.target" ];
      requiredBy = [ "machines.target" ];

      execConfig = {
        Timezone = "Bind";
        Hostname = "Arch";
        SystemCallFilter = "modify_ldt";
      };

      filesConfig = {
        Volatile = false;
        BindReadOnly = [ "/home/rolfst:/mnt/rolfst" ];
        Bind = [
          "/home/rolfst/.container-arch:/home/rolfst"
          "/run/user/1000/wayland-1"
          "/tmp/.X11-unix/X0"
          "/tank"
          "/run/user/1000/pulse/native"
          "/dev/dri"
          "/dev/shm"
        ];
      };

      networkConfig = {
        Private = true;
        VirtualEthernet = true;
        Bridge = "virbr0";
      };
    };

    # Vulkan support
    systemd.services."systemd-nspawn@".serviceConfig = {
      DeviceAllow = [ "char-drm rwx" "/dev/dri/renderD128" ];
    };
  };
}
