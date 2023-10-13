{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  options.modules.services.git-sync = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "sync git repositories";};

  config = mkIf config.modules.services.git-sync.enable {
    user.packages = [pkgs.git-sync];

    hm.services = {
      git-sync.enable = true;
      git-sync.repositories = [
        {
          name = "notes";
          path = "~/notes";
          uri = "git+ssh://git@github.com:rolfst/Notes.git";
          interval = 3600;
        }
      ];
    };
  };
}
