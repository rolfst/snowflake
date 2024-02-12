{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrValues mkIf mkEnableOption;
  cfg = config.modules.desktop.extensions."screenshot";
in {
  options.modules.desktop.extensions."screenshot" = {
    enable = mkEnableOption "screenshot";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = attrValues {inherit (pkgs) shutter;};
  };
}
