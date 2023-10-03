{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkMerge;
  cfg = config.modules.desktop.distraction.youtube;
in {
  options.modules.desktop.distraction.youtube = let
    inherit (lib.options) mkEnableOption;
    inherit (lib.types) str;
    inherit (lib.my) mkOpt;
  in {
    enable = mkEnableOption "Youtube music";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = let
        inherit (pkgs) makeDesktopItem youtube-music;
      in [
        (makeDesktopItem {
          name = "Youtube-Music";
          desktopName = "YouTube music";
          genericName = "Launch YouTube music client";
          icon = "youtube";
          exec = "${getExe youtube-music}";
          categories = ["Network"];
        })
      ];
    }
  ]);
}
