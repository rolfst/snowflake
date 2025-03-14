# Copyright (c) 2022 felschr. All Rights Reserved.
{
  options,
  config,
  lib,
  ...
}: let
  inherit (builtins) listToAttrs;
  inherit (lib.attrsets) mapAttrsToList nameValuePair;
  inherit (lib.lists) flatten;
  inherit (lib.modules) mkIf;

  cfg = config.modules.desktop.extensions.mimeApps;
in {
  options.modules.desktop.extensions.mimeApps = let
    inherit (lib.options) mkEnableOption;
    inherit (lib.types) str;
    inherit (lib.my) mkOpt;
  in {
    enable = mkEnableOption "default applications";
    defApps = {
      docViewer = mkOpt str "org.pwmt.zathura.desktop";
      editor = mkOpt str "emacsclient.desktop";
      fileBrowser = mkOpt str "org.gnome.Nautilus.desktop";
      imageViewer = mkOpt str "feh.desktop";
      mediaPlayer = mkOpt str "mpv.desktop";
      webBrowser = mkOpt str "firefox.desktop";
    };
  };

  config = mkIf cfg.enable {
    create.configFile."mimeapps.list".force = true;

    hm.xdg.mimeApps = {
      enable = true;
      defaultApplications = let
        defaultApps = let
          inherit (cfg.defApps) docViewer editor fileBrowser imageViewer mediaPlayer webBrowser;
        in {
          audio = [mediaPlayer];
          browser = [webBrowser];
          compression = [fileBrowser];
          directory = [fileBrowser];
          image = [imageViewer];
          mail = [editor];
          pdf = [docViewer];
          text = [editor];
          video = [mediaPlayer];
        };
        mimeMap = {
          audio = [
            "audio/aac"
            "audio/mpeg"
            "audio/ogg"
            "audio/opus"
            "audio/wav"
            "audio/webm"
            "audio/x-matroska"
          ];
          browser = [
            "text/html"
            "x-scheme-handler/about"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
            "x-scheme-handler/unknown"
          ];
          # calendar = [ "text/calendar" "x-scheme-handler/webcal" ];
          compression = [
            "application/bzip2"
            "application/gzip"
            "application/vnd.rar"
            "application/x-7z-compressed"
            "application/x-7z-compressed-tar"
            "application/x-bzip"
            "application/x-bzip-compressed-tar"
            "application/x-compress"
            "application/x-compressed-tar"
            "application/x-cpio"
            "application/x-gzip"
            "application/x-lha"
            "application/x-lzip"
            "application/x-lzip-compressed-tar"
            "application/x-lzma"
            "application/x-lzma-compressed-tar"
            "application/x-tar"
            "application/x-tarz"
            "application/x-xar"
            "application/x-xz"
            "application/x-xz-compressed-tar"
            "application/zip"
          ];
          directory = ["inode/directory"];
          image = [
            "image/bmp"
            "image/gif"
            "image/jpeg"
            "image/jpg"
            "image/png"
            "image/svg+xml"
            "image/tiff"
            "image/vnd.microsoft.icon"
            "image/webp"
          ];
          # mail = [ "x-scheme-handler/mailto" ];
          pdf = ["application/pdf"];
          text = ["text/plain"];
          video = [
            "video/mp2t"
            "video/mp4"
            "video/mpeg"
            "video/ogg"
            "video/webm"
            "video/x-flv"
            "video/x-matroska"
            "video/x-msvideo"
          ];
        };
      in
        listToAttrs (flatten (mapAttrsToList (key: types:
          map (type: nameValuePair type (defaultApps."${key}")) types)
        mimeMap));
    };
  };
}
