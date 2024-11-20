{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) isAttrs;
  inherit (lib) attrValues mkIf mkMerge mkOption;
  inherit (lib.types) nullOr enum;
  inherit (lib.my) anyAttrs countAttrs value;

  cfg = config.modules.desktop;
in {
  options.modules.desktop = let
    inherit (lib.types) either str;
    inherit (lib.my) mkOpt;
  in {
    type = mkOpt (either str null) null;
  };

  config = mkMerge [
    {
      assertions = let
        isEnabled = _: v: v.enable or false;
        hasDesktopEnabled = cfg:
          (anyAttrs isEnabled cfg)
          || !(anyAttrs (_: v: isAttrs v && anyAttrs isEnabled v) cfg);
      in [
        {
          assertion =
            (countAttrs (_: v: v.enable or false) cfg) < 2;
          message = "Can't have more than one desktop environment enabled at a time";
        }
        {
          assertion = hasDesktopEnabled cfg;
          message = "Can't enable a desktop sub-module without a desktop environment";
        }
        {
          assertion = !(hasDesktopEnabled cfg) || cfg.type != null;
          message = "Downstream desktop module did not set modules.desktop.type!";
        }
      ];
    }

    (mkIf (cfg.type != null) {
      home.sessionVariables.GTK_DATA_PREFIX = "${config.system.path}";

      system.userActivationScripts.cleanupHome = ''
        pushd "${config.user.home}"
        rm -rf .compose-cache .nv .pki .dbus .fehbg
        [ -s .xsession-errors ] || rm -f .xsession-errors*
        popd
      '';

      user.packages = attrValues {
        inherit
          (pkgs)
          nvfetcher
          clipboard-jh
          hyperfine
          gucharmap
          qgnomeplatform # Qt -> GTK Theme
          kalker
          ueberzugpp
          ;

        kalker-launcher = pkgs.makeDesktopItem {
          name = "Kalker";
          desktopName = "Kalker";
          icon = "calc";
          exec = "${config.modules.desktop.terminal.default} start kalker";
          categories = ["Education" "Science" "Math"];
        };
      };

      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
        packages = attrValues {inherit (pkgs) sarasa-gothic scheherazade-new;};
      };

      hm.qt = {
        enable = true;
        style.name = "adwaita-dark";
        platformTheme.name = "adwaita";
      };

      # Enabling usb connection for devices
      services.udisks2.enable = true;
      services.gvfs.enable = true;

      # Enabling xserver + x-related settings:
      services.xserver.enable = true;
      xdg.portal = {
        enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
        config.common.default = "*";
      };

      # Retain secrets inside Gnome Keyring
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.login.enableGnomeKeyring = true;

      # GUI for our gnome-keyring:
      programs.seahorse.enable = true;

      # Functional `pkgs.light` for `/bin/brightctl`
      programs.light.enable = true;

      # KDE-Connect + Start-up indicator
      # programs.kdeconnect = {
      #   enable = true;
      #   package = pkgs.valent;
      # };
    })

    (mkIf (cfg.type == "x11") {
      security.pam.services.login.enableGnomeKeyring = true;
      services.displayManager = {
        autoLogin.enable = true;
        autoLogin.user = config.user.name;
      };
      services.xserver = {
        enable = true;
        displayManager.lightdm = {
          enable = true;
          # greeters.mini = {
          #   enable = true;
          #   user = config.user.name;
          # };
        };
        resolutions = [
          {
            x = 1920;
            y = 1080;
          }
        ];
      };

      hm.xsession = {
        enable = true;
        numlock.enable = true;
        preferStatusNotifierItems = true;
      };
    })
  ];
}
