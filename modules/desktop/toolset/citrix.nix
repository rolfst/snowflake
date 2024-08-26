{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption attrValues mkMerge;

  cfg = config.modules.desktop.toolset.citrix;
in {
  options.modules.desktop.toolset.citrix = {
    enable = mkEnableOption "remote desktop for enterprises";
  };
  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = attrValues {
        inherit (pkgs) citrix_workspace;
      };
    })
  ];
}
