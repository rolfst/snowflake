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
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443 3000 3008];
      interfaces.podman1 = {
        allowedUDPPorts = [53]; # this needs to be there so that containers can look eachother's names up over DNS
      };
    };
    hardware.nvidia-container-toolkit.enable = true;
    virtualisation = {
      containers.enable = true;

      podman = {
        enable = true;
        dockerCompat = true; # docker = podman (alias)
        # For Nixos version > 22.11
        defaultNetwork.settings = {dns_enabled = true;};
        extraPackages = attrValues {inherit (pkgs) conmon runc skopeo;};
      };
      oci-containers.backend = "podman";
    };

    environment.shellAliases = {
      podman = "podman";
      # docker = "podman";
      pps = "podman ps --format 'table {{ .Names }}\t{{ .Status }}' --sort names";
      pclean = "podman ps -a | grep -v 'CONTAINER\|_config\|_data\|_run' | cut -c-12 | xargs podman rm 2>/dev/null";
      piclean = "podman images | grep '<none>' | grep -P '[1234567890abcdef]{12}' -o | xargs -L1 podman rmi 2>/dev/null";
    };
    # is this the new key for virtualisation.podman.enableNvidia
    # virtualisation.containers.cdi.dynamic.nvidia.enable = true;
  };
}
