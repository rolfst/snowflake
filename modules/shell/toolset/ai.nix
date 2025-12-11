{
  config,
  options,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.modules) mkIf;
in {
  options.modules.shell.toolset.AI = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "Agentic AI code base helper";};

  config = mkIf config.modules.shell.toolset.AI.enable {
    environment.systemPackages = with pkgs; [opencode];
  };
}
