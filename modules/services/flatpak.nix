{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  options.modules.services.flatpak = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "use flatpak";};

  config = mkIf config.modules.services.flatpak.enable {
    services.flatpak = {
      enable = true;
      update.auto.enable = false;
      uninstallUnmanaged = false;
      packages = [
        "com.getpostman.Postman"
      ];
    };
  };
}
