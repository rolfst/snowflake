{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf;
in {
  options.modules.virtualize.podman = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "Enable the Podman container engine";};

  config = mkIf config.modules.virtualize.podman.enable {
    virtualisation.podman = {
      enable = true;
      enableNvidia = true;
      dockerCompat = true; # docker = podman (alias)
      # For Nixos version > 22.11
      defaultNetwork.settings = {dns_enabled = true;};
      extraPackages = attrValues {inherit (pkgs) conmon runc skopeo;};
    };
  };
}
