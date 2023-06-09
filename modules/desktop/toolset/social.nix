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
  envProto = config.modules.desktop.envProto;
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
    element = {
      withDaemon = {
        enable =
          mkEnableOption "matrix daemon for ement"
          // {
            default = !cfg.element.withClient.enable;
          };
      };
      withClient = {
        enable =
          mkEnableOption "element client"
          // {
            default = cfg.base.enable && !cfg.element.withDaemon.enable;
          };
        package = mkOption {
          type = nullOr (enum ["element" "fractal"]);
          default = "fractal";
          description = "What display protocol to use.";
        };
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.base.enable {
      user.packages = attrValues {inherit (pkgs) signal-desktop tdesktop;};
    })

    (mkIf cfg.element.withDaemon.enable {
      hm.services.pantalaimon = {
        enable = true;
        settings = {
          Default = {
            LogLevel = "Debug";
            SSL = true;
          };
          local-matrix = {
            Homeserver = "https://matrix.org";
            ListenAddress = "127.0.0.1";
            ListenPort = 8009;
          };
        };
      };
    })

    (mkIf cfg.element.withClient.enable {
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
        if (cfg.element.withClient.package == "element")
        then [element-desktop']
        else [pkgs.fractal-next];
    })

    (mkIf cfg.discord.enable {
      home.configFile.openSAR-settings = {
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
          ++ optionals (envProto == "x11") [
            "--disable-features=UseOzonePlatform"
            "--enable-features=VaapiVideoDecoder"
          ]
          ++ optionals (envProto == "wayland") [
            "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer"
            "--ozone-platform=wayland"
            "--enable-webrtc-pipewire-capturer"
          ];

        discord-canary' =
          (pkgs.discord-canary.override {withOpenASAR = true;}).overrideAttrs
          (old: {
            preInstall = ''
              gappsWrapperArgs+=("--add-flags" "${concatStringsSep " " flags}")
            '';
          });
      in [discord-canary'];
    })
  ];
}
