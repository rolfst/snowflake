{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrValues mkIf mkEnableOption;
  cfg = config.modules.desktop.extensions."2fa";
in {
  options.modules.desktop.extensions."2fa" = {
    enable = mkEnableOption "2-factor authentication";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = attrValues {inherit (pkgs) authy;};
  };
}
