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
        type = "wayland";
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
          waybar.enable = true;
          elkowar.enable = true;
          rofi.enable = true;
        };
      };
      # modules.shell.scripts = {
      #   brightness.enable = true;
      #   screenshot.enable = true; # TODO
      # };

      programs.niri.enable = true;
      modules.hardware.kmonad.enable = false;
      hm = {
        imports = [
          inputs.noctalia.homeModules.default
        ];
        programs = {
          noctalia-shell = {
            enable = true;
            systemd.enable = true;
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
                  enable = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                keybind-cheatsheet = {
                  enable = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                clipper = {
                  enable = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                notes-scratchpad = {
                  enable = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                screenshot = {
                  enable = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
              };
            };
          };
        };
      };

      create.configFile = {
        niri_conf = {
          target = "niri/config.kdl";
          source = "${niriDir}/config.kdl";
        };
      };

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
