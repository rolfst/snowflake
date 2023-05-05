{ options, config, lib, pkgs, ... }: let
  inherit (lib) attrValues mkIf mkEnableOption;
  cfg = config.modules.desktop.toolset.keybase;
in {
  options.modules.desktop.extensions.keybase = {
    enable = mkEnableOption "Keybase GUI";
  };
  config = mkIf cfg.enable  {
    environment.systemPackages = attrValues {inherit (pkgs) keybase-gui;};
  };

}
