{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) getEnv;
  inherit (lib.modules) mkIf;

  cfg = config.modules.shell.gnupg;
in {
  options.modules.shell.gnupg = let
    inherit (lib.options) mkEnableOption;
    inherit (lib.types) int;
    inherit (lib.my) mkOpt;
  in {
    enable = mkEnableOption "cryptographic suite";
    cacheTTL = mkOpt int 86400; # 24 hours
  };

  config = mkIf config.modules.shell.gnupg.enable {
    # Unlock GnuPG automatically
    security.pam.services.${config.user.name}.gnupg = {
      enable = true;
      noAutostart = true;
      storeOnly = true;
    };

    hm.programs.gpg = {
      enable = true;
      homedir = "${config.hm.xdg.configHome}/gnupg";
      settings = {
        keyserver = "keys.openpgp.org";
      };
    };

    # Enables Gnome3 pinentry usage
    services.dbus.packages = [pkgs.gcr];

    hm.services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gtk2;

      defaultCacheTtl = cfg.cacheTTL;
      defaultCacheTtlSsh = cfg.cacheTTL;
      maxCacheTtl = cfg.cacheTTL;
      maxCacheTtlSsh = cfg.cacheTTL;

      extraConfig = ''
        allow-emacs-pinentry
        allow-loopback-pinentry
        allow-preset-passphrase
      '';
    };
  };
}
