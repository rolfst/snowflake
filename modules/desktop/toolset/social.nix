{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrValues optionals;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.strings) concatStringsSep;

  cfg = config.modules.desktop.toolset.social;
  desktop = config.modules.desktop;
in {
  options.modules.desktop.toolset.social = let
    inherit (lib.options) mkEnableOption mkOption;
    inherit (lib.types) nullOr enum;
  in {
    base.enable = mkEnableOption "cross-platform clients";
    discord.enable =
      mkEnableOption "discord client"
      // {
        default = cfg.base.enable;
      };
    slack.enable = mkEnableOption "slack client";
    matrix = {
      #   withDaemon = {
      #     enable =
      #       mkEnableOption "matrix daemon for ement.el"
      #       // {
      #         default = !cfg.matrix.withClient.enable;
      #       };
      #   };
      withClient = {
        enable =
          mkEnableOption "rust-based matrix client"
          // {
            default = cfg.base.enable && !cfg.matrix.withDaemon.enable;
          };
        package = mkOption {
          type = nullOr (enum ["element" "fractal"]);
          default = "element";
          description = "What display protocol to use.";
        };
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.base.enable {
      user.packages = attrValues {inherit (pkgs) signal-desktop tdesktop;};
    })
    (mkIf cfg.slack.enable {
      user.packages = attrValues {inherit (pkgs) slack teamviewer;};
    })

    # (mkIf cfg.matrix.withDaemon.enable {
    #   hm.nixpkgs.overlays = [
    #     (final: prev: {
    #       pantalaimon = prev.pantalaimon.overrideAttrs (old: {
    #         version = "0.10.5-dev";
    #         src = final.fetchFromGitHub {
    #           owner = "matrix-org";
    #           repo = old.pname;
    #           rev = "3968c69aa846889970df1372ba9aa54c1c5e4290";
    #           sha256 = "sha256-JdoJB68QtxPhFeZCHd+0ZOlUDbQV3HeBsxW0KbhnDSs=";
    #         };
    #       });
    #     })
    #   ];

    #   hm.services.pantalaimon = {
    #     enable = true;
    #     settings = {
    #       Default = {
    #         LogLevel = "Debug";
    #         SSL = true;
    #       };
    #       local-matrix = {
    #         Homeserver = "https://matrix.org";
    #         ListenAddress = "localhost";
    #         ListenPort = 8009;
    #         IgnoreVerification = true;
    #         UseKeyring = false;
    #       };
    #     };
    #   };
    # })

    (mkIf cfg.matrix.withClient.enable {
      user.packages = let
        inherit (pkgs) makeWrapper symlinkJoin element-desktop;
        element-desktop' = symlinkJoin {
          name = "element-desktop-in-dataHome";
          paths = [element-desktop];
          nativeBuildInputs = [makeWrapper];
          postBuild = ''
            wrapProgram "$out/bin/element-desktop" \
              --add-flags '--profile-dir $XDG_DATA_HOME/Element'
          '';
        };
      in
        if (cfg.matrix.withClient.package == "element")
        then [element-desktop']
        else [pkgs.fractal-next];
    })

    (mkIf cfg.discord.enable {
      create.configFile.openSAR-settings = {
        target = "discordcanary/settings.json";
        text = builtins.toJSON {
          openasar = {
            setup = true;
            quickstart = true;
            noTyping = false;
            cmdPreset = "balanced";
            css = ''
              @import url("https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css");
            '';
          };
          SKIP_HOST_UPDATE = true;
          IS_MAXIMIZED = true;
          IS_MINIMIZED = false;
          trayBalloonShown = true;
        };
      };

      user.packages = let
        flags =
          [
            "--flag-switches-begin"
            "--flag-switches-end"
            "--disable-gpu-memory-buffer-video-frames"
            "--enable-accelerated-mjpeg-decode"
            "--enable-accelerated-video"
            "--enable-gpu-rasterization"
            "--enable-native-gpu-memory-buffers"
            "--enable-zero-copy"
            "--ignore-gpu-blocklist"
          ]
          ++ optionals (desktop.type == "x11") [
            "--disable-features=UseOzonePlatform"
            "--enable-features=VaapiVideoDecoder"
          ]
          ++ optionals (desktop.type == "wayland") [
            "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer"
            "--ozone-platform=wayland"
            "--enable-webrtc-pipewire-capturer"
          ];

        # discord-canary' =
        discord' =
          # (pkgs.discord-canary.override {withOpenASAR = true;}).overrideAttrs
          (pkgs.discord.override {withOpenASAR = true;}).overrideAttrs
          (old: {
            preInstall = ''
              gappsWrapperArgs+=("--add-flags" "${concatStringsSep " " flags}")
            '';
          });
        # in [discord-canary'];
      in [discord'];
    })
  ];
}
