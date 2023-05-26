
{ inputs, options, config, lib, pkgs, ... }:

let
  inherit (lib.attrsets) attrValues;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;

  # getMaxResolution = drv:
  # let
  #   name = builtins.parseDrvName drv.name;
  #   cmd = pkgs.runCommand "max-resolution" { } ''
  #     export DISPLAY=${pkgs.xorg.xauth.display} && ${pkgs.xorg.xrandr} -q | awk '/^${name} connected/ { getline; print $NF }' | head -1 > $out
  #   '';
  # in
  #   pkgs.stdenv.mkDerivation {
  #     name = "max-resolution";
  #     builder = "${pkgs.stdenv.shell}";
  #     args = [ "-c" cmd ];
  #     inherit pkgs;
  #   };

  # Define a function to get the screen identifier using xrandr
  # getScreenIdentifier = drv:
  # let
  #   name = builtins.parseDrvName drv.name;
  #   cmd = pkgs.runCommand "screen-identifier" { } ''
  #     export DISPLAY=${pkgs.xorg.xauth.display} && ${pkgs.xorg.xrandr} -q | awk '/^${name} connected/ { print $1 }' > $out
  #   '';
  # in
  #   pkgs.stdenv.mkDerivation {
  #     name = "screen-identifier";
  #     builder = "${pkgs.stdenv.shell}";
  #     args = [ "-c" cmd ];
  #     inherit pkgs;
  #   };
in {
  options.modules.desktop.xmonad = let inherit (lib.options) mkEnableOption mkOption;
  in {
    enable = mkEnableOption "haskell (superior) WM";
    screenResolution = mkOption {
      type = lib.types.attrs;
      description = "A set of options to specif the desired screen resolution";
      default = {
        enable = false;
        width = 1920;
        height = 1080;
      };
    };
  };

  config = mkIf config.modules.desktop.xmonad.enable {
    modules.desktop = {
      envProto = "x11";
      toolset.fileBrowse = { nautilus.enable = true; };
      extensions = {
        fcitx5.enable = true;
        mimeApps.enable = true; # mimeApps -> default launch application
        picom = {
          enable = true;
          animation.enable = true;
        };
        dunst.enable = true;
        rofi.enable = true;
        taffybar.enable = true;
        elkowar.enable = true;
      };
    };
    modules.shell.scripts = {
      brightness.enable = true;
      microphone.enable = true;
      volume.enable = true;
      screenshot.enable = true;
    };
    # module.hardware.kmonad.enable = true;

    nixpkgs.overlays = [ inputs.xmonad-contrib.overlay ];

    environment.systemPackages = attrValues ({
      inherit (pkgs) libnotify playerctl gxmessage xdotool xclip feh arandr;
    });

    services.greetd = {
      settings.initial_session = { command = "none+xmonad"; };
    };

    services.xserver = {
      windowManager.session = [{
        name = "xmonad";
        start = ''
          /usr/bin/env birostrisWM &
          waitPID=$!
        '';
      }];
    };

    hm.xsession.windowManager = {
      command = "${getExe pkgs.haskellPackages.birostrisWM}";
    };
  };
}
