{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.modules.desktop.toolset.fileManager;
in
{
  options.modules.desktop.toolset.fileManager =
    let
      inherit (lib.options) mkEnableOption mkOption;
      inherit (lib.types) nullOr enum;
    in
    {
      enable = mkEnableOption "A file-browser for our desktop";
      program = mkOption {
        type = nullOr (enum [
          "dolphin"
          "nautilus"
          "thunar"
        ]);
        default = "thunar";
        description = "which file-browser to install";
      };
    };

  config = mkMerge [
    {
      # :NOTE| Notify system about our file-browser
      modules.desktop.extensions.mimeApps.defApps.fileBrowser = "${cfg.program}.desktop";
      modules.desktop.extensions.mimeApps.defApps.archiveManager = "engrampa.desktop";
      services.gvfs.enable = true;

      environment.systemPackages = attrValues (
        { }
        // optionalAttrs (cfg.program == "dolphin") {
          inherit (pkgs) dolphin dolphin-plugins;
        }
        // optionalAttrs (cfg.program == "nautilus") {
          inherit (pkgs.gnome) nautilus;
        }
        // optionalAttrs (cfg.program == "thunar") {
          inherit (pkgs) file-roller;
        }
      );
    }

    (mkIf (cfg.program == "thunar") {
      programs.xfconf.enable = true;
      services.tumbler.enable = true;
      programs.thunar = {
        enable = true;
        plugins = with pkgs.xfce; [
          thunar-volman
          thunar-archive-plugin
          thunar-media-tags-plugin
        ];
      };

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
      };

      hm.xfconf.settings."thunar" = {
        "last-view" = "ThunarDetailsView";
      };
    })
  ];
}
