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

  config = mkIf config.modules.shell.mise.enable (let
    defShell = config.modules.shell.default;
  in {
    user.packages = attrValues {inherit (pkgs.unstable) mise;};

    hm.programs.mise = {
      enable = true;
      enableZshIntegration = defShell == "zsh";
      enableBashIntegration = defShell == "bash";
      enableFishIntegration = defShell == "fish";
      enableNushellIntegration = defShell == "nushell";
    };
    hm.programs.direnv.mise.enable = true;
  });
}
