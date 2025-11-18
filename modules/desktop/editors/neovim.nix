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
          inherit (pkgs.unstable) vectorcode uv;

          # inherit (pkgs) neovide;
          # inherit (pkgs.vimPlugins) markdown-preview-nvim;
          inherit (pkgs.lua51Packages) luarocks tiktoken_core jsregexp;
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
          python3Packages.prompt-toolkit
          python3Packages.requests
        ];
        extraPython3Packages = ps:
          with ps; [
            prompt_toolkit
            requests
          ];
        plugins = with pkgs.unstable.vimPlugins; [
          nvim-dap-vscode-js
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
        ];
      };

      # Required API key for ChatGPT:
      # home.sessionVariables.OPENAI_API_KEY = "$(cat /run/agenix/closedAI)";
    }

    (mkIf cfg.rolfst.enable {
      modules.develop.lua.enable = true;

      create = {
        configFile."nvim" = {
          source = "${inputs.nvim-dir}";
          recursive = true;
        };

        configFile."nvim/after/plugin/dap-js.lua" = {
          text = ''
             local status_dap_ok, dap = pcall(require, "dap")
             if not status_dap_ok then
                 return
             end
             local status_ok, dap_vscode_js = pcall(require, "dap-vscode-js")
             if not status_ok then
                 return
             end
            for _, adapter in ipairs({
                "pwa-node",
                "pwa-chrome",
                "pwa-msedge",
                "node-terminal",
                "pwa-extensionHost",
            }) do
                dap.adapters[adapter] = {
                type = "server",
                host = "localhost",
                port = "''${port}",
                executable = {
                    command = "node",
                    args = {
                    "${pkgs.vscode-js-debug.outPath}" .. "/lib/node_modules/js-debug/dist/src/dapDebugServer.js",
                    "''${port}",
                    },
                },
                }
            end
          '';

          # dap_vscode_js.setup({
          #     node_path = "node",  -- Path of node executable. Defaults to $NODE_PATH, and then "node"
          #     debugger_path = "${pkgs.vscode-js-debug.outPath}", -- Path to vscode-js-debug installation.
          #     -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
          #     port = 8123,
          #     adapters = {
          #     "pwa-node",
          #     "pwa-chrome",
          #     "pwa-msedge",
          #     "node-terminal",
          #     "pwa-extensionHost",
          #     }, -- which adapters to register in nvim-dap
          # })
        };
      };
    })
  ];
}
