{ config, options, lib, pkgs, ... }:

let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.modules) mkIf;

  cfg = config.modules.desktop.toolset.recorder;
in {
  options.modules.desktop.toolset.recorder =
    let inherit (lib.options) mkEnableOption;
    in {
      enable = mkEnableOption false;
      audio.enable = mkEnableOption "audio manipulation" // { default = true; };
      video.enable = mkEnableOption "video manipulation" // { default = true; };
    };

  config = mkIf cfg.enable {
    services.pipewire.jack.enable = true;

    boot.extraModulePackages = mkIf cfg.video.enable [
      config.boot.kernelPackages.v4l2loopback
    ];
    boot.kernelModules = mkIf cfg.video.enable [ "v4l2loopback" ];
    boot.extraModprobeConfig = mkIf cfg.video.enable ''
      options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
    '';

    user.packages = attrValues ({
      inherit (pkgs) ffmpeg;
    } // optionalAttrs cfg.audio.enable {
      inherit (pkgs.unstable) audacity crosspipe;
    } // optionalAttrs cfg.video.enable {
      inherit (pkgs.unstable) handbrake;
      obs-studio = pkgs.unstable.wrapOBS {
        plugins = [ pkgs.unstable.obs-studio-plugins.wlrobs ];
      };
    });
  };
}
