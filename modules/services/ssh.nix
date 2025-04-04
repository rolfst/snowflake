{
  options,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) filter pathExists;
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf;
in {
  options.modules.services.ssh = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "secure-socket shell";};

  config = mkIf config.modules.services.ssh.enable {
    programs.ssh.startAgent = true;

    user.packages = attrValues {
      inherit (pkgs) openssl;
    };

    services.openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        # startWhenNeeded = true;
      };

      # hostKeys = [{
      #   comment = "icy-thought@host";
      #   path = "/etc/ssh/ed25519_key";
      #   rounds = 100;
      #   type = "ed25519";
      # }];
    };

    user.openssh.authorizedKeys.keyFiles =
      if config.user.name == "rolfst"
      then
        filter pathExists [
          "${config.user.home}/.ssh/id_ed25519_rolfstgm.pub"
          "${config.user.home}/.ssh/id_rsa.pub"
        ]
      else [];
  };
}
