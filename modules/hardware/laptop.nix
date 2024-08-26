{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.attrsets) attrValues;
  cfg = config.modules.hardware.laptop;
in {
  options.modules.hardware.laptop = let
    inherit (lib.options) mkEnableOption;
  in {
    enable = mkEnableOption "laptop support";
  };

  config = mkMerge [
    (
      mkIf cfg.enable {
        services.auto-cpufreq.enable = true;
        services.auto-cpufreq.settings = {
          battery = {
            governor = "powersave";
            turbo = "never";
          };
          charger = {
            governor = "performance";
            turbo = "auto";
          };
        };
      }
    )
  ];
}
