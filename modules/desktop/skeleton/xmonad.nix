{
  inputs,
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
in {
  options.modules.desktop.xmonad = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "Haskell-based (functional) window manager";};

  config = mkIf config.modules.desktop.xmonad.enable {
    modules.desktop = {
      type = "x11";
      terminal.default = "kitty";
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
        picom = {
          enable = true;
          animation.enable = true;
        };
        dunst.enable = true;
        rofi.enable = true;
        taffybar.enable = true;
        # elkowar.enable = true;
      };
    };
    modules.shell.scripts = {
      brightness.enable = true;
      screenshot.enable = true;
    };
    modules.hardware.kmonad.enable = true;

    nixpkgs.overlays = [inputs.xmonad.overlay inputs.xmonad-contrib.overlay];

    environment.systemPackages = attrValues {
      inherit (pkgs) libnotify playerctl gxmessage xdotool feh arandr zenity;
      inherit (pkgs.xorg) xwininfo;
    };
    hm.xsession.windowManager.xmonad = {
      enable = true;
      extraPackages = haskellPackages: [
        haskellPackages.aeson
        haskellPackages.bytestring
        haskellPackages.hostname
        haskellPackages.multimap
        haskellPackages.tuple
        haskellPackages.safe
        haskellPackages.split
        haskellPackages.utf8-string
        haskellPackages.xdg-desktop-entry
        haskellPackages.xmonad-contrib
      ];
    };
    create.configFile.xmonad-conf = {
      target = "${config.user.home}/.xmonad/xmonad.hs";
      source = "${config.snowflake.configDir}/xmonad/xmonad.hs";
    };

    services.greetd = {
      settings.initial_session = {command = "none+xmonad";};
    };

    # services.displayManager = {
    #   defaultSession = "none+xmonad";
    # };
    services.xserver.displayManager = {
      session = [
        {
          manage = "window";
          name = "none_xmonad";
          bgsupport = true;
          start = ''
            systemd-cat -t xmonad -- ${pkgs.runtimeShell} $HOME/.xsession > /dev/null 2>&1 &
            waitPID=$!
          '';
        }
      ];
      # windowManager.xmonad = {
      #   enable = true;
      #   enableContribAndExtras = true;
      #   flake = {
      #       enable = true;
      #       compiler = "ghc947";
      #   };
      #   config = ${getExe pkgs.haskellPackages.birostrisWM};
      #   enableConfiguredRecompile = true;
      # }
    };
  };
}
