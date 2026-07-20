{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (pkgs) writeScriptBin;
in {
  options.modules.shell.scripts.tsession = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "tmux sessionizer";};

  config = mkIf config.modules.shell.tmux.enable {
    user.packages = [
      (writeScriptBin "tsession" ''
        #!/usr/bin/env bash

        WORKSPACE_DIR="$HOME/workspaces"

        if [[ $# -eq 1 ]]; then
            selected=$1
        else
            # Collect existing tmux sessions
            LIST_SESSIONS=""
            if tmux list-sessions 2>/dev/null; then
                LIST_SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | while read -r session; do
                    session_path=$(tmux display-message -t "$session" -p '#{pane_current_path}' 2>/dev/null)
                    echo -e "  $session (active)\t$session_path"
                done)
            fi

            # Collect workspace directories
            LIST_DIRS=$(${pkgs.fd}/bin/fd -td . "$WORKSPACE_DIR" \
                --min-depth 1 \
                --max-depth 3 \
                --exclude={node_modules,src,build,dist,bin,.git} | while read -r dirpath; do
                    echo -e "  $(basename "$dirpath")\t$dirpath"
                done)

            # Combine and select
            selected=$(echo -e "$LIST_SESSIONS\n$LIST_DIRS" | grep -v '^$' | ${pkgs.fzf}/bin/fzf \
                --delimiter='\t' \
                --with-nth=1 \
                --height=40% \
                --reverse \
                --header="Select workspace or session" | cut -f2)
        fi

        if [[ -z $selected ]]; then
            exit 0
        fi

        # If selected is an existing tmux session name (active session picked)
        if tmux has-session -t="$selected" 2>/dev/null; then
            tmux switch-client -t "$selected"
            exit 0
        fi

        # Otherwise treat as directory path — create or switch to session
        selected_name=$(basename "$selected" | tr . _)
        tmux_running=$(pgrep tmux)

        if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
            tmux new-session -s "$selected_name" -c "$selected"
            exit 0
        fi

        if ! tmux has-session -t="$selected_name" 2>/dev/null; then
            tmux new-session -ds "$selected_name" -c "$selected"
        fi

        tmux switch-client -t "$selected_name"
      '')

      (writeScriptBin "tsession-rm" ''
        #!/usr/bin/env bash

        # List tmux sessions for multi-select removal
        SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

        if [[ -z $SESSIONS ]]; then
            echo "No active tmux sessions."
            exit 0
        fi

        SELECTION=$(echo "$SESSIONS" | ${pkgs.fzf}/bin/fzf -m \
            --height=40% \
            --reverse \
            --header="KILL SESSION(S)" \
            --color=header:red)

        if [[ -n $SELECTION ]]; then
            echo "Sessions to kill:"
            echo "$SELECTION"
            read -p "Confirm (y/N): " CONFIRM
            if [[ "$CONFIRM" =~ ^[yY]$ ]]; then
                echo "$SELECTION" | while read -r session; do
                    tmux kill-session -t "$session"
                    echo "Killed: $session"
                done
            fi
        fi
      '')
    ];
  };
}
