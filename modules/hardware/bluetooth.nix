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
    (
      mkIf cfg.enable {
        services.blueman.enable = true;

        hardware.bluetooth = {
          enable = true;
          # supportA2dp = true;
          # supportHfp = true;
          # supportHsp = true;
          powerOnBoot = true;
          settings.General = {
            ControllerMode = "bredr";
            Experimental = true;
            Enable = "Source,Sink,Media,Socket";
          };
        };
      }
    )
  ];
}
