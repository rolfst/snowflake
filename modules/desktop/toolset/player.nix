{
  inputs,
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.modules.desktop.toolset.player;
in
{
  options.modules.desktop.toolset.player =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
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
    #     theme = themes.tokiyo-night;
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
          inherit (pkgs.mpvScripts)
            autoload
            mpris
            sponsorblock
            thumbfast
            uosc
            ;
        };
        config = {
          # Rendering — gpu-next is the modern replacement for gpu-hq
          vo = "gpu-next";
          gpu-api = "vulkan";
          hwdec = "auto-safe"; # VA-API on Intel iGPU, fallback to software

          force-window = true;
          ytdl-format = "bestvideo+bestaudio";
          cache = "yes";
          demuxer-max-bytes = "512MiB";
          demuxer-max-back-bytes = "128MiB";

          osc = "no"; # Disabled for uosc

          # Scaling (high quality)
          scale = "ewa_lanczos";
          dscale = "mitchell";
          cscale = "ewa_lanczos";

          # Deband (reduces banding artifacts in dark scenes)
          deband = "yes";
          deband-iterations = 4;
          deband-threshold = 35;
          deband-range = 16;
          deband-grain = 5;

          watch-later-dir = "${config.hm.xdg.dataHome}/watch_later";
          save-position-on-quit = "yes";

          # Subtitles
          sub-font = "Trebuchet MS";
          sub-font-size = 35;
          sub-shadow-offset = 2;
          sub-shadow-color = "0.0/0.0/0.0";
        };
        scriptOpts = {
          autoload.same_type = true;
          thumbfast = {
            spawn_first = true;
            network = true;
            hwdec = true;
          };
        };
        bindings = {
          WHEEL_UP = "seek 10";
          WHEEL_DOWN = "seek -10";
        };
      };

      user.packages = [ pkgs.mpvc ];
    })
  ];
}
