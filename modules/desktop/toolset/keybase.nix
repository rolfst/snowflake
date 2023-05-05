{ options, config, lib, pkgs, ... }: let
  inherit (lib) mkIf mkEnableOption attrValues mkMerge;

  cfg = config.modules.desktop.toolset.keybase;
in {
  options.modules.desktop.toolset.keybase = {
    enable = mkEnableOption "status-bar for wayland";
  };
  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = attrValues {
        inherit (pkgs) keybase kbfs;
      };
      hm.services = {
        keybase.enable = true;
        kbfs.enable = true;
        kbfs.mountPoint = "keybase";
      };
    })
  ];
}
