{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  options.modules.desktop.editors.libreoffice = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "post-modern office suit";};

  config = mkIf config.modules.desktop.editors.libreoffice.enable {
    hm.programs.libreoffice = {
      package = pkgs.libreoffice;
    };
  };
}
