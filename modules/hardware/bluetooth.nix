{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.attrsets) attrValues;
  cfg = config.modules.hardware.bluetooth;
in {
  options.modules.hardware.bluetooth = let
    inherit (lib.options) mkEnableOption;
  in {
    enable = mkEnableOption "bluetooth support";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = attrValues {
        inherit (pkgs) blueman;
      };
      hardware.bluetooth = {
        enable = true;
        disabledPlugins = ["sap"];
      };
    })
  ];
}
