{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkMerge;
  cfg = config.modules.desktop.distraction.steam;
in
{
  options.modules.desktop.distraction.steam =
    let
      inherit (lib.options) mkEnableOption;
      inherit (lib.types) str;
      inherit (lib.my) mkOpt;
    in
    {
      enable = mkEnableOption "game/software store";
      hardware.enable = mkEnableOption "Steam-based HW support";
      libDir = mkOpt str "$XDG_DATA_HOME/steamlib";
    };

  config = mkIf cfg.enable (mkMerge [
    {
      # when running steam on x11 do this
      # I avoid programs.steam.enable because it installs another steam binary,
      # which the xdesktop package invokes, instead of my steam shims below.
      # user.packages = let
      #   inherit
      #     (pkgs)
      #     makeDesktopItem
      #     stdenv
      #     steam
      #     steam-run
      #     writeScriptBin
      #     ;
      # in [
      #   # Get steam to keep its garbage out of $HOME
      #   (writeScriptBin "steam" ''
      #     #!${stdenv.shell}
      #     HOME="${cfg.libDir}" exec ${getExe steam} "$@"
      #   '')
      #
      #   # for running GOG and humble bundle games
      #   (writeScriptBin "steam-run" ''
      #     #!${stdenv.shell}
      #     HOME="${cfg.libDir}" exec ${getExe steam-run} "$@"
      #   '')
      #
      # Add rofi desktop icon
      #   (makeDesktopItem {
      #     name = "steam";
      #     desktopName = "Steam";
      #     icon = "steam";
      #     exec = "steam";
      #     terminal = false;
      #     mimeTypes = ["x-scheme-handler/steam"];
      #     categories = ["Network" "FileTransfer" "Game"];
      #   })
      # ];

      # system.userActivationScripts.setupSteamDir = ''
      #   mkdir -p "${cfg.libDir}"
      # '';

      # for running steam under wayland do this:
      programs = {
        steam = {
          enable = true;
          gamescopeSession = {
            enable = true;
            args = [
              "--prefer-vk-device 10de"  # Prefer NVIDIA Vulkan device (vendor ID 0x10de)
            ];
          };
          extraPackages = with pkgs; [
            gamescope
          ];
        };
        gamemode = {
          enable = true;
          settings = {
            gpu = {
              apply_gpu_optimisations = "accept-responsibility";
              gpu_vendor = "nvidia";
              nv_powertarget = 100;
              nv_core_clock_mhz_offset = 0;
              nv_mem_clock_mhz_offset = 0;
            };
          };
        };
      };

      # Force Steam and all Proton games to use the NVIDIA dGPU
      environment.sessionVariables = {
        # PRIME Render Offload for Steam
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        # Proton/DXVK should target NVIDIA Vulkan
        DXVK_FILTER_DEVICE_NAME = "NVIDIA";
      };

      environment.systemPackages = with pkgs; [
        mangohud
        protonup-qt
        lutris
        bottles
        heroic
      ];

      # better for steam proton games
      # systemd.extraConfig = "DefaultLimitNOFILE=1048576";
    }

    (mkIf cfg.hardware.enable { hardware.steam-hardware.enable = true; })
  ]);
}
