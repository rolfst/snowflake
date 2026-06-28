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
          elkowar.enable = false; # noctalia v5 is native C++, not eww/quickshell
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
          noctalia = {
            enable = true;
            systemd.enable = false;
            settings = builtins.fromJSON (readFile "${niriDir}/noctalia.json");
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
        # NOTE: noctalia v5 manages plugins via `noctalia msg plugins` IPC.
        # Do NOT generate plugins.json — a read-only nix-store symlink blocks
        # v5 from writing its own plugin state.  After rebuild, enable plugins:
        #   noctalia msg plugins source add "Official" "https://github.com/noctalia-dev/official-plugins"
        #   noctalia msg plugins enable noctalia/screen_recorder
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
          brightnessctl
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
        # Screen/window sharing via xdg-desktop-portal is broken on niri+NVIDIA PRIME
        # (niri#2223, niri#3700) — unresolved upstream. The bug: niri exports DMA-BUF
        # with MOD_INVALID modifier; apps using the other GPU's EGL cannot import it.
        # Workaround: use OBS wlr-screencopy capture + v4l2loopback virtual camera.
        extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        config.niri = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.Access" = "gtk";
          "org.freedesktop.impl.portal.Notification" = "gtk";
          "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
          "org.freedesktop.impl.portal.ScreenCast" = "gnome";
          "org.freedesktop.impl.portal.Screenshot" = "gnome";
        };
      };

      # Required for xdp-gnome's screencasting to work — niri ships systemd
      # user units that wire up graphical-session.target correctly.
      systemd.packages = [ pkgs.niri ];

      # xdg-desktop-portal-gnome renders its own GTK4/Vulkan picker window.
      # The global NVIDIA env vars (GBM_BACKEND, VK_DRIVER_FILES, etc.) that we
      # set for niri + the screencasting pipeline leak into xdp-gnome and cause
      # VK_SUBOPTIMAL_KHR swapchain errors that prevent the picker from rendering.
      # Unset them for the portal so it falls back to the Intel iGPU for its UI.
      hm.xdg.configFile."systemd/user/xdg-desktop-portal-gnome.service.d/unset-nvidia.conf".text = ''
        [Service]
        Environment="GBM_BACKEND="
        Environment="VK_DRIVER_FILES="
        Environment="__GLX_VENDOR_LIBRARY_NAME="
        Environment="DXVK_FILTER_DEVICE_NAME="
        Environment="__VK_LAYER_NV_optimus="
      '';

    };
}
