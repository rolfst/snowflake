{
  inputs,
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.strings) concatStringsSep;

  cfg = config.modules.desktop.browsers;
  isDefault = cfg.default == "zen";
in {
  options.modules.desktop.browsers.zen = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "Zen browser a modern firefox based browser";};

  config = mkIf cfg.zen.enable (mkMerge [
    {
      user.packages = [inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default];
    }

    # :NOTE| Notify system about our default browser
    (mkIf isDefault {
      home.sessionVariables.BROWSER = "zen";
      modules.desktop.extensions.mimeApps.defApps.webBrowser = "zen.desktop";
    })
  ]);
}
