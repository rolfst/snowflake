{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.attrsets) attrValues;
  cfg = config.modules.desktop.distraction.youtube;
in {
  options.modules.desktop.distraction.youtube = let
    inherit (lib.options) mkEnableOption;
  in {
    enable = mkEnableOption "Youtube music";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = attrValues {
        inherit (pkgs) youtube-music;
      };
    }
  ]);
}
