{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  cfg = config.modules.develop.cloud;
in {
  options.modules.develop.cloud = let
    inherit (lib.options) mkEnableOption;
  in {
    aws.enable = mkEnableOption "AWS CLI";
    azure.enable = mkEnableOption "Azure CLI";
  };

  config = mkMerge [
    (mkIf cfg.aws.enable {
      user.packages = attrValues {
        inherit (pkgs) awscli2;
      };
    })

    (mkIf cfg.azure.enable {
      user.packages = attrValues {
        inherit (pkgs) azure-cli;
      };
    })
  ];
}
