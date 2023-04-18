{ config, options, pkgs, lib, ... }:

let
  inherit (builtins) map;
  inherit (lib) mapAttrsToList mkIf;
  inherit (lib.strings) concatStrings escapeNixString optionalString;

  cfg = config.modules.shell;
in {
  config = mkIf (cfg.default == "nushell") {
    modules.shell.usefulPkgs.enable = true;

    # Custom shell modules:
    modules.shell.macchina.enable = true;
    modules.shell.xplr.enable = true;

    # Enable starship-rs:
    modules.shell.starship.enable = true;
    hm.programs.starship.enableNusellIntegration = true;

    # Enable completion for sys-packages:
    environment.pathsToLink = [ "/share/nu" ];

    # Enable nixpkgs suggestions:
    programs.nushell.enable = true;

    hm.programs.nushell = {
      enable = true;
    };
};
