{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf;
in {
  options.modules.shell.mise = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "mise-en-place";};

  config = mkIf config.modules.shell.mise.enable {
    user.packages = attrValues {inherit (pkgs.unstable) mise;};

    hm.programs.mise = {
      enable = true;
      enableZshIntegration = true;
    };
    hm.programs.direnv.mise.enable = true;
  };
}
