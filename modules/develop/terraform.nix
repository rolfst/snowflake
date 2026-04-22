{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  cfg = config.modules.develop.terraform;
in {
  options.modules.develop.terraform = let
    inherit (lib.options) mkEnableOption;
  in {
    enable = mkEnableOption "Terraform development";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = attrValues {
        inherit (pkgs) terraform-ls;
        inherit (pkgs) tflint;
      };
    })

    (mkIf config.modules.develop.xdg.enable {}) # TODO
  ];
}
