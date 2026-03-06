{
  inputs,
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
in
{
  options.modules.desktop.virtual.winapps =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "WinApps (Windows applications via RDP)";
    };

  config = mkIf config.modules.desktop.virtual.winapps.enable {
    user.packages = [
      inputs.winapps.packages."${pkgs.system}".winapps
      inputs.winapps.packages."${pkgs.system}".winapps-launcher
    ];
  };
}
