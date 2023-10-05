{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  options.modules.hardware.printer = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "printer support";};

  config = mkIf config.modules.hardware.printer.enable {
    services.printing = {
      enable = true;
      drivers = [pkgs.hplip pkgs.xsane];
    };
    user.packages = [pkgs.xsane];

    hardware.sane = {
      enable = true;
      extraBackends = [pkgs.hplipWithPlugin];
    };
    # Enable wireless access to printers
    services.avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };
  };
}
