{
  inputs,
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) readFile;
  inherit (lib) mkIf;
  inherit (lib.strings) optionalString;
  inherit (lib.my) mkBoolOpt;

  cfg = config.modules.desktop.extensions.polybar;
  polyDir = "${config.snowflake.configDir}/polybar";
in {
  options.modules.desktop.extensions.polybar = {enable = mkBoolOpt false;};

  config = mkIf cfg.enable {
    # WARN: 2-Step workaround (https://github.com/polybar/polybar/issues/403)
    gtk.iconCache.enable = true;

    services.xserver = {
      gdk-pixbuf.modulePackages = [pkgs.librsvg];
      displayManager.sessionCommands = ''
        # 1st-Step polybar workaround
        systemctl --user import-environment GDK_PIXBUF_MODULE_FILE DBUS_SESSION_BUS_ADDRESS PATH
      '';
    };

    # WARN: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files
    services.gnome.at-spi2-core.enable = true;

    hm.services = {
      # Allow tray-icons to be displayed:
      status-notifier-watcher.enable = true;

      polybar = {
        enable = true;
      };
    };

    # Symlink necessary files for config to load:
    home.configFile = let
      active = config.modules.themes.active;
    in {
      polybar-base = {
        target = "polybar/polybar.hs";
        source = "${polyDir}/polybar.hs";
        onChange = "rm -rf $XDG_CACHE_HOME/polybar";
      };
      polybar-palette = mkIf (active != null) {
        target = "polybar/palette/${active}.css";
        source = "${polyDir}/palette/${active}.css";
      };
      polybar-css = {
        target = "polybar/polybar.css";
        text = ''
          ${optionalString (active != null) ''
            @import url("./palette/${active}.css");
          ''}
          ${readFile "${polyDir}/polybar.css"}
        '';
      };
    };
  };
}
