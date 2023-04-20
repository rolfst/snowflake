{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf attrValues mkOption mkMerge;
  inherit (lib.types) package;
  inherit (lib.my) mkBoolOpt;

  cfg = config.modules.desktop.toolset.keybase;
in {
  options.modules.desktop.toolset.keybase = {
    enable = mkBoolOpt false;
  };
  config = mkMerge [
    (mkIf cfg.modules.desktop.toolset.keybase.enable {
      environment.systemPackages = attrValues {
        inherit (pkgs) keybase kbfs;
      };
      hm.services = {
        keybase.enable = true;
        kbfs.mountPoint = "secure/";
      };
    })
  ];
}
