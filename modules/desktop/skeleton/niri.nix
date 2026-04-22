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
        type = [ "wayland" ];
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
          dunst.enable = false;
          waybar.enable = false;
          elkowar.enable = false; # noctalia-shell uses quickshell, not eww
          rofi.enable = true;
        };
      };
      # modules.shell.scripts = {
      #   brightness.enable = true;
      #   screenshot.enable = true; # TODO
      # };

      programs.niri.enable = true;

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
            systemd.enable = false;
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
                network-manager-vpn = {
                  enabled = true;
                  sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                };
                tailscale = {
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
        kanshi_conf = {
          target = "kanshi/config";
          source = "${config.snowflake.configDir}/kanshi/config";
        };
      };
      hardware.graphics.enable32Bit = true;

      environment.extraInit = ''
        if [ "$XDG_SESSION_DESKTOP" = "niri" ]; then
          export NIXOS_OZONE_WL=1

          # VA-API video decode: let the system-wide LIBVA_DRIVER_NAME (set per-host
          # in hardware.nix) decide which GPU handles decode.  On PRIME-offload
          # laptops the Intel iGPU (iHD) is the correct VA-API provider — forcing
          # "nvidia" here caused scrambled video because the dGPU is powered off in
          # offload mode.
          export MOZ_DISABLE_RDD_SANDBOX=1

          # Ensure Vulkan uses NVIDIA ICD
          export VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json

          # GBM backend for Wayland EGL (NVIDIA).
          # Required for xdg-desktop-portal-gnome to deliver PipeWire frames correctly.
          # Screenshare worked with this set; removing it broke portal capture.
          export GBM_BACKEND=nvidia-drm
          export __GLX_VENDOR_LIBRARY_NAME=nvidia

        fi
      '';

      environment.systemPackages = attrValues {
        inherit (pkgs)
          imv
          kanshi
          libnotify
          playerctl
          wl-clipboard
          wdisplays
          wf-recorder
          wlr-randr
          gpu-screen-recorder
          swaylock
          ;
      };

      hm.systemd.user.services.kanshi = {
        Unit = {
          Description = "Dynamic output configuration for Wayland compositors";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${lib.meta.getExe pkgs.kanshi}";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      xdg.portal = {
        # niri implements org.gnome.Mutter.ScreenCast natively — xdp-gnome is
        # the correct portal for screencasting on niri (per niri docs).
        # xdp-wlr crashes (SIGSEGV in wlr_frame_damage) on niri 25.11.
        extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        # Match upstream NixOS niri module config exactly:
        # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/wayland/niri.nix
        config.niri = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.Access" = "gtk";
          "org.freedesktop.impl.portal.Notification" = "gtk";
          "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
        };
      };

      # Required for xdp-gnome's screencasting to work — niri ships systemd
      # user units that wire up graphical-session.target correctly.
      systemd.packages = [ pkgs.niri ];

    };
}
