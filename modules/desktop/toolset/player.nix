{
  inputs,
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.modules.desktop.toolset.player;
in {
  options.modules.desktop.toolset.player = let
    inherit (lib.options) mkEnableOption;
  in {
    music.enable = mkEnableOption "music player";
    video.enable = mkEnableOption "video player";
  };

  config = mkMerge [
    # (mkIf cfg.music.enable {
    #   hm.imports = [ inputs.spicetify-nix.homeManagerModules.default ];
    #
    #   hm.programs.spicetify = let
    #     inherit (inputs.spicetify-nix.packages.${pkgs.system}.default)
    #       apps extensions themes;
    #   in {
    #     enable = true;
    #     spotifyPackage = pkgs.spotify-unwrapped;
    #     spicetifyPackage = pkgs.spicetify-cli;
    #
    #     theme = themes.catppuccin-mocha;
    #     colorScheme = "flamingo";
    #
    #     enabledCustomApps = [ apps.new-releases apps.lyrics-plus ];
    #     enabledExtensions = [
    #       extensions.adblock
    #       extensions.fullAppDisplay
    #       extensions.hidePodcasts
    #       extensions.keyboardShortcut
    #       extensions.playNext
    #       extensions.showQueueDuration
    #       extensions.shuffle
    #     ];
    #   };
    # })

    (mkIf cfg.video.enable {
      hm.programs.mpv = {
        enable = true;
        scripts = attrValues {
          inherit (pkgs.mpvScripts) autoload mpris sponsorblock thumbfast uosc;
        };
        config = {
          profile = "gpu-hq";
          force-window = true;
          ytdl-format = "bestvideo+bestaudio";
          cache-default = 4000000;
          osc = "no"; # Thumbnail
          watch-later-dir = "${config.hm.xdg.dataHome}/watch_later";

          sub-font = "Trebuchet MS";
          sub-font-size = 35;
          sub-shadow-offset = 2;
          sub-shadow-color = "0.0/0.0/0.0";
        };
        scriptOps.autoload.same_type = true;
        bindings = {
          WHEEL_UP = "seek 10";
          WHEEL_DOWN = "seek -10";
        };
      };

      user.packages = [pkgs.mpvc];
    })
  ];
}
