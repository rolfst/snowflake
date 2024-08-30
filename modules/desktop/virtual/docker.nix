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
  options.modules.virtualize.docker = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "container manipulation";};

  config = mkIf config.modules.virtualize.docker.enable {
    user.packages = attrValues {inherit (pkgs) docker docker-compose;};

    home.sessionVariables = {
      DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
      MACHINE_STORAGE_PATH = "$XDG_DATA_HOME/docker/machine";
    };

    user.extraGroups = ["docker"];

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
        enableOnBoot = false;
        # listenOptions = [];
      };
    };
  };
}
