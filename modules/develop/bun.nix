{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
in {
  options.modules.develop.bun = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "Bun JS/TS runtime";};

  config = mkMerge [
    (mkIf config.modules.develop.bun.enable {
      user.packages = attrValues {inherit (pkgs) bun;};
    })

    (mkIf config.modules.develop.xdg.enable {
      home.sessionVariables = {
        BUN_INSTALL = "$XDG_DATA_HOME/bun";
      };

      home.sessionPath = ["$BUN_INSTALL/bin"];
    })
  ];
}
