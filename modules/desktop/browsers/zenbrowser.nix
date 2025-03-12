{
  inputs,
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatStringsSep;
in {
  options.modules.desktop.browsers.zen = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "Zen browser a modern firefox based browser";};

  config = mkIf config.modules.desktop.browsers.zen.enable {
    user.packages = [inputs.zen-browser.packages."${pkgs.system}".default];
  };
}
