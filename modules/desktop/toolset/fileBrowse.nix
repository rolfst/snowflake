{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.modules.desktop.toolset.fileManager;
in {
  options.modules.desktop.toolset.fileManager = let
    inherit (lib.options) mkEnableOption mkOption;
    inherit (lib.types) nullOr enum;
  in {
    enable = mkEnableOption "A file-browser for our desktop";
    program = mkOption {
      type = nullOr (enum ["dolphin" "nautilus" "thunar"]);
      default = "thunar";
      description = "which file-browser to install";
    };
  };

  config = mkMerge [
    {
      # :NOTE| Notify system about our file-browser
      modules.desktop.extensions.mimeApps.defApps.fileBrowser = cfg.program;
      services.gvfs.enable = true;

      environment.systemPackages = attrValues ({}
        // optionalAttrs (cfg.program == "dolphin") {
          inherit (pkgs) dolphin dolphin-plugins;
        }
        // optionalAttrs (cfg.program == "nautilus") {
          inherit (pkgs.gnome) nautilus;
        }
        // optionalAttrs (cfg.program == "thunar") {
          inherit
            (pkgs.xfce)
            thunar
            thunar-volman
            thunar-archive-plugin
            thunar-media-tags-plugin
            ;
          inherit (pkgs.mate) engrampa;
        });
    }

    (mkIf (cfg.program == "thunar") {
      services.tumbler.enable = true;

      create.configFile = {
        "Thunar/uca.xml".text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <actions>
          <action>
                  <icon>kitty</icon>
                  <name>Launch Kitty Here</name>
                  <unique-id>1653079815094995-1</unique-id>
                  <command>kitty --working-directory %f</command>
                  <description>Example for a custom action</description>
                  <patterns>*</patterns>
                  <startup-notify/>
                  <directories/>
          </action>
          </actions>
        '';

        "xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
          <?xml version="1.0" encoding="UTF-8"?>

          <channel name="thunar" version="1.0">
            <property name="last-view" type="string" value="ThunarIconView"/>
            <property name="last-icon-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_150_PERCENT"/>
            <property name="last-window-width" type="int" value="946"/>
            <property name="last-window-height" type="int" value="503"/>
            <property name="last-window-maximized" type="bool" value="false"/>
            <property name="last-side-pane" type="string" value="ThunarTreePane"/>
            <property name="last-separator-position" type="int" value="213"/>
            <property name="last-location-bar" type="string" value="ThunarLocationEntry"/>
            <property name="misc-single-click" type="bool" value="false"/>
            <property name="misc-thumbnail-mode" type="string" value="THUNAR_THUMBNAIL_MODE_ALWAYS"/>
            <property name="misc-text-beside-icons" type="bool" value="false"/>
            <property name="misc-date-style" type="string" value="THUNAR_DATE_STYLE_SHORT"/>
            <property name="shortcuts-icon-size" type="string" value="THUNAR_ICON_SIZE_32"/>
            <property name="tree-icon-size" type="string" value="THUNAR_ICON_SIZE_24"/>
            <property name="last-menubar-visible" type="bool" value="false"/>
          </channel>
        '';
      };
    })
  ];
}
