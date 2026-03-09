{
  options,
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.desktop.browsers = let
    inherit (lib.options) mkOption;
    inherit (lib.types) nullOr str;
  in {
    default = mkOption {
      type = nullOr str;
      default = null;
      description = "Default system browser";
      example = "google";
    };
  };
}
