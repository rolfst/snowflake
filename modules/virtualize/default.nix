{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf;

  cfg = config.modules.virtualize;
in {
  options.modules.virtualize = let
    inherit (lib.options) mkEnableOption;
  in {
    enable = mkEnableOption "Spawn virtual envionrments where required.";
  };

  config = mkIf cfg.enable {
    user.packages = attrValues {
      inherit (pkgs) virt-manager virt-viewer win-virtio spice spice-gtk spice-protocol win-spice;
    };

    virtualisation = {
      libvirtd = {
        enable = true;
        # extraOptions = ["--verbose"];
        extraConfig = ''user="rolfst"'';
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
          ovmf = {
            enable = true;
            packages = [pkgs.OVMFFull.fd];
          };
          verbatimConfig = ''
            namespaces = []
            user = "rolfst"
          '';
        };
      };
      spiceUSBRedirection.enable = true;
    };
    user.extraGroups = ["libvirtd" "qemu-libvirtd"];

    services.spice-vdagentd.enable = true;

    # Fix: Could not detect a default hypervisor. Make sure the appropriate QEMU/KVM virtualization...
    hm.dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };
  };
}
