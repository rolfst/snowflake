{
  inputs,
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrValues mkIf mkMerge;
  inherit (lib.my) mkBoolOpt;

  cfg = config.modules.desktop.toolset.player;
in {
  options.modules.desktop.toolset.player = {
    music.enable = mkBoolOpt false;
    video.enable = mkBoolOpt false;
  };

  config = mkMerge [
    (mkIf cfg.video.enable {
      hm.programs.mpv = {
        enable = true;
        scripts = attrValues {
          inherit (pkgs.mpvScripts) autoload mpris sponsorblock thumbnail;
        };
        config = {
          profile = "gpu-hq";
          force-window = true;
          ytdl-format = "bestvideo+bestaudio";
          cache-default = 4000000;
          osc = "no"; # Thumbnail
        };
        bindings = {
          WHEEL_UP = "seek 10";
          WHEEL_DOWN = "seek -10";
        };
      };

      user.packages = [pkgs.mpvc];
    })
  ];
}
