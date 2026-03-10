{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) toString;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.strings) concatStringsSep;

  cfg = config.modules.desktop.browsers;
  isDefault = cfg.default == "ungoogled";
in
{
  options.modules.desktop.browsers.ungoogled =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "Google-free chromium";
    };

  config = mkIf cfg.ungoogled.enable (mkMerge [
    {
    # user.packages = let inherit (pkgs) makeDesktopItem ungoogled-chromium;
    user.packages =
      let
        inherit (pkgs) makeDesktopItem google-chrome;
      in
      [
        (makeDesktopItem {
          name = "ungoogled-private";
          desktopName = "Ungoogled Web Browser (Private)";
          genericName = "Launch a Private Ungoogled Chromium Instance";
          icon = "chromium";
          exec = "${getExe google-chrome} --incognito";
          categories = [ "Network" ];
        })
      ];

    # hm.programs.chromium = {
    hm.programs.google-chrome = {
      enable = true;
      package =
        let
          ungoogledFlags = toString [
            "--force-dark-mode"
            # "--disable-search-engine-collection"
            "--extension-mime-request-handling=always-prompt-for-install"
            "--fingerprinting-canvas-image-data-noise"
            "--fingerprinting-canvas-measuretext-noise"
            "--fingerprinting-client-rects-noise"
            "--popups-to-tabs"
            "--show-avatar-button=incognito-and-guest"

            # Performance
            "--enable-gpu-rasterization"
            "--enable-oop-rasterization"
            "--enable-zero-copy"
            "--ignore-gpu-blocklist"

            # Experimental features
            "--enable-features=${
              concatStringsSep "," [
                "BackForwardCache:enable_same_site/true"
                "CopyLinkToText"
                "OverlayScrollbar"
                "TabHoverCardImages"
                "AcceleratedVideoDecodeLinuxGL"
                "AcceleratedVideoDecodeLinuxZeroCopyGL"
                "AcceleratedVideoEncoder"
              ]
            }"

            # Workaround for cross-GPU DMA-BUF compositing on hybrid Intel+NVIDIA
            "--disable-gpu-compositing"
          ];
          # in pkgs.ungoogled-chromium.override {
        in
        pkgs.google-chrome.override {
          commandLineArgs = [ ungoogledFlags ];
        };
    };
    }

    # :NOTE| Notify system about our default browser
    (mkIf isDefault {
      home.sessionVariables.BROWSER = "chromium";
      modules.desktop.extensions.mimeApps.defApps.webBrowser = "chromium-browser.desktop";
    })
  ]);
}
