{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) attrValues optionalAttrs;
in {
  options.modules.desktop.editors.libreoffice = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "post-modern office suit";};

  config = mkIf config.modules.desktop.editors.libreoffice.enable {
    user.packages = attrValues {
      inherit (pkgs) libreoffice;
    };
  };
}
