{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrValues;
  inherit (lib.my) mkBoolOpt;
  cfg = config.modules.desktop.toolset.keybase;
in {
  options.modules.desktop.extension.keybase = {
    enable = mkBoolOpt false;
  };
  config = {environment.systemPackages = attrValues {inherit (pkgs) keybase-gui;};};
}
