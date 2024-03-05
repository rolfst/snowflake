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
    package = mkOpt package pkgs.unstable.neovim-unwrapped;
    agasaya.enable = mkEnableOption "nvim (lua) config";
    ereshkigal.enable = mkEnableOption "nvim (lisp) config";
    rolfst.enable = mkEnableOption "nvim personal config";
  };

  config = mkMerge [
    {
      user.packages = attrValues ({
          inherit (pkgs) neovide;
          # inherit (pkgs.vimPlugins) markdown-preview-nvim;
          inherit (pkgs.lua51Packages) luarocks;
          # inherit (pkgs.unstable.vimPlugins.nvim-treesitter) withAllGrammars;
          # inherit (pkgs.unstable.vimPlugins.nvim-treesitter-parsers) css haskell javascript jsdoc json nix markdown python rust typescript tsx toml yaml;
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
        extraPackages = with pkgs.unstable; [
          python3Packages.pynvim
          python3Packages.prompt-toolkit
          python3Packages.requests
        ];
        extraPython3Packages = ps:
          with ps; [
            pynvim
            prompt_toolkit
            requests
          ];
        # plugins = with pkgs.unstable.vimPlugins; [
        #   nvim-treesitter.withAllGrammars
        #   nvim-treesitter-parsers.css
        #   nvim-treesitter-parsers.haskell
        #   nvim-treesitter-parsers.javascript
        #   nvim-treesitter-parsers.jsdoc
        #   nvim-treesitter-parsers.json
        #   nvim-treesitter-parsers.nix
        #   nvim-treesitter-parsers.markdown
        #   nvim-treesitter-parsers.python
        #   nvim-treesitter-parsers.rust
        #   nvim-treesitter-parsers.typescript
        #   nvim-treesitter-parsers.tsx
        #   nvim-treesitter-parsers.toml
        #   nvim-treesitter-parsers.yaml
        # ];
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
        # configFile."nvim/parser".source = "${pkgs.symlinkJoin {
        #   name = "treesitter-parsers";
        #   paths =
        #     (pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins:
        #       with plugins; [
        #         c
        #         lua
        #         query
        #         python
        #         vim
        #         vimdoc
        #         typescript
        #       ]))
        #     .dependencies;
        # }}/parser";
      };
    })
  ];
}
