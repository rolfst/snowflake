{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.modules) mkIf mkMerge;
  cfg = config.modules.develop.lua;
in {
  options.modules.develop.lua = let
    inherit (lib.options) mkEnableOption;
  in {
    enable = mkEnableOption "Lua development";
    fennel.enable = mkEnableOption "Lisp-based Lua development";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = attrValues ({
          inherit (pkgs.lua51Packages) lua;
          inherit (pkgs) lua-language-server stylua;
          inherit (pkgs) selene;
        }
        // optionalAttrs (cfg.fennel.enable) {inherit (pkgs) fennel fnlfmt;});

      create.configFile.stylua-conf = {
        target = "stylua/stylua.toml";
        text = ''
          column_width = 80
          line_endings = "Unix"
          indent_type = "Spaces"
          indent_width = 4
          quote_style = "AutoPreferDouble"
          call_parentheses = "Always"
        '';
      };
    })

    (mkIf config.modules.develop.xdg.enable {}) # TODO
  ];
}
