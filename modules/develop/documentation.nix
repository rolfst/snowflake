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
  options.modules.develop.documentation =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "Documentation tooling (typst + d2 diagrams)";
    };

  config = mkIf config.modules.develop.documentation.enable {
    user.packages = attrValues {
      inherit (pkgs) typst d2;
      inherit (pkgs.my) typst-d2-mcp;
    };
  };
}
