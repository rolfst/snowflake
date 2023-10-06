{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (pkgs) python3 writeScriptBin;
in {
  options.modules.shell.scripts.tsession = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "tmux sessionizer";};

  config = mkIf config.modules.shell.tmux.enable {
    user.packages = [
      (writeScriptBin "tsession" ''
        #!/usr/bin/env bash

        if [[ $# -eq 1 ]]; then
            selected=$1
        else
            selected=$(fd -td --full-path . "$HOME/workspaces" --exclude={node_modules,src,build,dist,bin} --min-depth 1 --max-depth 2 | fzf)
        fi

        if [[ -z $selected ]]; then
            exit 0
        fi

        selected_name=$(basename "$selected" | tr . _)
        echo $selected_name
        tmux_running=$(pgrep tmux)

        if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
            echo "tmux running $tmux_running"
            tmux new-session -s $selected_name -c $selected
            exit 0
        fi

        if ! tmux has-session -t=$selected_name 2> /dev/null; then
            echo "tmux has no session"
            tmux new-session -ds $selected_name -c $selected
        fi

        tmux switch-client -t $selected_name
      '')
    ];
  };
}
