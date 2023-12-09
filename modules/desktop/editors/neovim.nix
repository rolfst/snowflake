{
  config,
  options,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.modules.desktop.editors.neovim;
in {
  options.modules.desktop.editors.neovim = let
    inherit (lib.options) mkEnableOption;
    inherit (lib.types) package;
    inherit (lib.my) mkOpt;
  in {
    package = mkOpt package pkgs.neovim-unwrapped;
    agasaya.enable = mkEnableOption "nvim (lua) config";
    ereshkigal.enable = mkEnableOption "nvim (lisp) config";
    rolfst.enable = mkEnableOption "nvim personal config";
  };

  config = mkMerge [
    {
      user.packages = attrValues ({
          inherit (pkgs) neovide;
          inherit (pkgs.vimPlugins) markdown-preview-nvim;
          inherit (pkgs.lua51Packages) luarocks;
        }
        // optionalAttrs (config.modules.develop.cc.enable == false) {
          inherit (pkgs) gcc; # Treesitter
        });

      hm.programs.neovim = {
        enable = true;
        package = cfg.package;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
      };

      # Required API key for ChatGPT:
      # env.OPENAI_API_KEY = "$(cat /run/agenix/closedAI)";
    }

    (mkIf cfg.rolfst.enable {
      modules.develop.lua.enable = true;

      home.configFile = {
        rolfst-config = {
          target = "nvim";
          source = "${inputs.nvim-dir}";
          recursive = true;
        };
      };
    })
  ];
}
