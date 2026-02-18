{
  options,
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) readFile toPath;
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf;
in
{
  options.modules.desktop.niri =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "hyped wayland WM";
    };

  config =
    let
      niriDir = "${config.snowflake.configDir}/niri";
    in
    mkIf config.modules.desktop.niri.enable {
      modules.desktop = {
        type = ["wayland"];
        toolset.fileManager = {
          enable = true;
          program = "thunar";
        };
        extensions = {
          input-method = {
            enable = true;
            framework = "fcitx";
          };
          mimeApps.enable = true; # mimeApps -> default launch application
          dunst.enable = true;
          waybar.enable = false;
          elkowar.enable = true;
          rofi.enable = true;
        };
      };
      # modules.shell.scripts = {
      #   brightness.enable = true;
      #   screenshot.enable = true; # TODO
      # };

      programs.xwayland.enable = false;
      programs.niri.enable = true;

      modules.hardware.kmonad.enable = false;
      user.packages = with pkgs; [
        xwayland-satellite
      ];
      hm = {
        imports = [
          inputs.noctalia.homeModules.default
        ];
        programs = {
          noctalia-shell = {
            enable = true;
            systemd.enable = true;
            settings = builtins.fromJSON (readFile "${niriDir}/noctalia.json");
            plugins = {
              sources = [
                {
                  enabled = true;
                  name = "Official Noctalia Plugins";
                  url = "https://github.com/noctalia-dev/noctalia-plugins";
                }
              ];
              states = {
                screen-recorder = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                keybind-cheatsheet = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                clipper = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                notes-scratchpad = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                screenshot = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                assistant-panel = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                todo = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
              };
            };
          };
        };
      };
      environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text =
        lib.mkForce ''
            {
              "rules": [
                  {
                      "pattern": {
                          "feature": "procname",
                          "matches": "niri"
                      },
                      "profile": "Limit Free Buffer Pool On Wayland Compositors"
                  }
              ],
              "profiles": [
                  {
                      "name": "Limit Free Buffer Pool On Wayland Compositors",
                      "settings": [
                          {
                              "key": "GLVidHeapReuseRatio",
                              "value": 0
                          }
                      ]
                  }
              ]
          }
        '';

      create.configFile = {
        niri_conf = {
          target = "niri/config.kdl";
          source = "${niriDir}/config.kdl";
        };
      };
      hardware.graphics.enable32Bit = true;

      environment.extraInit = ''
        if [ "$XDG_SESSION_DESKTOP" = "niri" ]; then
          export WLR_NO_HARDWARE_CURSORS=1
          export NIXOS_OZONE_WL=1
        fi
      '';

      environment.systemPackages = attrValues {
        inherit (pkgs)
          imv
          libnotify
          playerctl
          wl-clipboard
          wf-recorder
          wlr-randr
          gpu-screen-recorder
          swaylock
          ;
      };
    };
}
