{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrValues mkIf mkMerge mkOption;
  inherit (lib.types) str;

  cfg = config.modules.desktop.editors;
in {
  options.modules.desktop.editors = {
    default = mkOption {
      type = str;
      default = "nvim";
      description = "Default editor for text manipulation";
      example = "nvim";
    };
  };

  config = mkMerge [
    (mkIf (cfg.default != null) {home.sessionVariables.EDITOR = cfg.default;})

    (mkIf (cfg.default == "nvim" || cfg.default == "emacs") {
      user.packages = attrValues {
        inherit (pkgs) imagemagick editorconfig-core-c sqlite deno pandoc markdownlint-cli marksman yamllint;
        aspellPlusDict =
          pkgs.aspellWithDicts
          (dict: with dict; [en en-computers en-science]);
      };
    })
  ];
}
