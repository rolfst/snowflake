{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf;
in
{
  options.modules.develop.kubernetes =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "Kubernetes CLI (kubectl)";
    };

  config = mkIf config.modules.develop.kubernetes.enable {
    user.packages = attrValues {
      inherit (pkgs) kubectl k9s;
    };
  };
}
