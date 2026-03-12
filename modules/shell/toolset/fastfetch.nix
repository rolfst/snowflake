{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;

  cfg = config.modules.shell.toolset.fastfetch;
in {
  options.modules.shell.toolset.fastfetch = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "system info on terminal startup";};

  config = mkIf cfg.enable {
    user.packages = [pkgs.fastfetch];

    hm.programs.zsh.initContent = mkIf (config.modules.shell.default == "zsh") ''
      fastfetch
    '';

    hm.programs.bash.bashrcExtra = ''
      fastfetch
    '';

    hm.programs.nushell.extraConfig = mkIf (config.modules.shell.default == "nushell") ''
      fastfetch
    '';

    create.configFile.fastfetch = {
      target = "fastfetch/config.jsonc";
      text = builtins.toJSON {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          type = "small";
        };
        display = {
          separator = "  ";
        };
        modules = [
          "title"
          "separator"
          "os"
          "host"
          "kernel"
          "uptime"
          "packages"
          "shell"
          "display"
          "de"
          "wm"
          "terminal"
          "cpu"
          "gpu"
          "memory"
          "disk"
          "battery"
          "break"
          "colors"
        ];
      };
    };
  };
}
