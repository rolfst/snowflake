{ config, options, lib, pkgs, ... }:

let inherit (lib.modules) mkIf;
in {
  options.modules.shell.tmux = let inherit (lib.options) mkEnableOption;
  in { enable = mkEnableOption "terminal multiplexer"; };

  config = mkIf config.modules.shell.tmux.enable {
    hm.programs.tmux = {
      enable = true;
      secureSocket = true;
      keyMode = "vi";
      prefix = "C-a";
      terminal = "tmux-256color";

      baseIndex = 1;
      clock24 = true;
      disableConfirmationPrompt = true;
      escapeTime = 0;

      aggressiveResize = false;
      resizeAmount = 2;
      reverseSplit = false;
      historyLimit = 5000;
      newSession = true;

      plugins = let inherit (pkgs.tmuxPlugins) resurrect continuum sensible vim-tmux-navigator;
      in [
        {
          plugin = resurrect;
          extraConfig = "set -g @resurrect-strategy-nvim 'session'";
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '60' # minutes
          '';
        }
        { plugin = sensible; }
        { plugin = vim-tmux-navigator; }
      ];

      extraConfig =
        let inherit (config.modules.themes.colors.main) normal types;
        in ''
          # -------===[ Color Correction ]===------- #
          set-option -ga terminal-overrides ",*256col*:Tc"
          set-option -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
          set-environment -g COLORTERM "truecolor"

          # -------===[ General-Configurations ]===------- #
          set-option -g renumber-windows on
          set-window-option -g automatic-rename on
          set-window-option -g word-separators ' @"=()[]'

          set-option -g mouse on
          set-option -s focus-events on
          set-option -g renumber-windows on
          set-option -g allow-rename off

          # -------===[ Activity/Sound ]===------- #
          set-option -g bell-action none
          set-option -g visual-bell off
          set-option -g visual-silence off
          set-option -g visual-activity off
          set-window-option -g monitor-activity off

          # -------===[ Keybindings ]===------- #
          # Window Control(s):
          bind-key Q kill-session
          # bind-key Q kill-server
          bind-key c new-window -c '#{pane_current_path}'

          # Buffers:
          bind-key b list-buffers
          bind-key p paste-buffer
          bind-key P choose-buffer

          # Split bindings:
          bind-key - split-window -v -c '#{pane_current_path}'
          bind-key / split-window -h -c '#{pane_current_path}'

          # Copy/Paste bindings:
          bind-key -T copy-mode-vi v send-keys -X begin-selection     -N "Start visual mode for selection"
          bind-key -T copy-mode-vi y send-keys -X copy-selection      -N "Yank text into buffer"
          bind-key -T copy-mode-vi c-v send-keys -X rectangle-toggle    -N "Yank region into buffer"

          # -------===[ Status-Bar ]===------- #
          set-option -g status on
          set-option -g status-interval 1
          set-option -g status-style bg=default,bold

          set-option -g status-position bottom
          set-option -g status-justify left

          # set-option -g status-left-length "40"
          # set-option -g status-right-length "80"

          # Messages:
          set-option -g message-style fg="${types.bg}",bg="${types.highlight}",align="centre"
          set-option -g message-command-style fg="${types.bg}",bg="${types.highlight}",align="centre"

          # Panes:
          set-option -g pane-border-style fg="${types.fg}"
          set-option -g pane-active-border-style fg="${types.border}"

          # Windows:
          set-option -g window-status-format "#[fg=${types.fg}] #W/#{window_panes} "
          set-option -g window-status-current-format "#{?client_prefix,#[fg=${types.bg}]#[bg=${normal.red}] #I:#W #[fg=${normal.red}]#[bg=default],#[fg=${types.bg}]#[bg=${types.border}] #I:#W #[fg=${types.border}]#[bg=default]}"

          # -------===[ Statusline ]===------- #
# # NOTE: Checking for the value of @catppuccin_window_tabs_enabled
#  local wt_enabled
#  wt_enabled="$(get_tmux_option "@catppuccin_window_tabs_enabled" "off")"
#  readonly wt_enabled
#
#  local right_separator
#  right_separator="$(get_tmux_option "@catppuccin_right_separator" "")"
#  readonly right_separator
#
#  local left_separator
#  left_separator="$(get_tmux_option "@catppuccin_left_separator" "")"
#  readonly left_separator
#
#  local user
#  user="$(get_tmux_option "@catppuccin_user" "off")"
#  readonly user
#
#  local host
#  host="$(get_tmux_option "@catppuccin_host" "off")"
#  readonly host
#
#  local date_time
#  date_time="$(get_tmux_option "@catppuccin_date_time" "off")"
#  readonly date_time
#
#  # These variables are the defaults so that the setw and set calls are easier to parse.
#  local show_directory
#  readonly show_directory="#[fg=$thm_pink,bg=$thm_bg,nobold,nounderscore,noitalics]$right_separator#[fg=$thm_bg,bg=$thm_pink,nobold,nounderscore,noitalics]  #[fg=$thm_fg,bg=$thm_gray] #{b:pane_current_path} #{?client_prefix,#[fg=$thm_red]"
#
#  local show_window
#  readonly show_window="#[fg=$thm_pink,bg=$thm_bg,nobold,nounderscore,noitalics]$right_separator#[fg=$thm_bg,bg=$thm_pink,nobold,nounderscore,noitalics] #[fg=$thm_fg,bg=$thm_gray] #W #{?client_prefix,#[fg=$thm_red]"
#
#  local show_session
#  readonly show_session="#[fg=$thm_green]}#[bg=$thm_gray]$right_separator#{?client_prefix,#[bg=$thm_red],#[bg=$thm_green]}#[fg=$thm_bg] #[fg=$thm_fg,bg=$thm_gray] #S "
#
#  local show_directory_in_window_status
#  #readonly show_directory_in_window_status="#[fg=$thm_bg,bg=$thm_blue] #I #[fg=$thm_fg,bg=$thm_gray] #{b:pane_current_path} "
#  readonly show_directory_in_window_status="#[fg=$thm_bg,bg=$thm_blue] #I #[fg=$thm_fg,bg=$thm_gray] #W "
#
#  local show_directory_in_window_status_current
#  #readonly show_directory_in_window_status_current="#[fg=$thm_bg,bg=$thm_orange] #I #[fg=$thm_fg,bg=$thm_bg] #{b:pane_current_path} "
#  readonly show_directory_in_window_status_current="#[fg=colour232,bg=$thm_orange] #I #[fg=colour255,bg=colour237] #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev) "
#
#  local show_window_in_window_status
#  readonly show_window_in_window_status="#[fg=$thm_fg,bg=$thm_bg] #W #[fg=$thm_bg,bg=$thm_blue] #I#[fg=$thm_blue,bg=$thm_bg]$left_separator#[fg=$thm_fg,bg=$thm_bg,nobold,nounderscore,noitalics] "
#
#  local show_window_in_window_status_current
#  readonly show_window_in_window_status_current="#[fg=$thm_fg,bg=$thm_gray] #W #[fg=$thm_bg,bg=$thm_orange] #I#[fg=$thm_orange,bg=$thm_bg]$left_separator#[fg=$thm_fg,bg=$thm_bg,nobold,nounderscore,noitalics] "
# #setw -g window-status-current-format "#[fg=colour232,bg=$thm_orange] #I #[fg=colour255,bg=colour237] #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev) "
#
#
#  local show_user
#  readonly show_user="#[fg=$thm_blue,bg=$thm_gray]$right_separator#[fg=$thm_bg,bg=$thm_blue] #[fg=$thm_fg,bg=$thm_gray] #(whoami) "
#
#  local show_host
#  readonly show_host="#[fg=$thm_blue,bg=$thm_gray]$right_separator#[fg=$thm_bg,bg=$thm_blue]󰒋 #[fg=$thm_fg,bg=$thm_gray] #H "
#
#  local show_date_time
#  readonly show_date_time="#[fg=$thm_blue,bg=$thm_gray]$right_separator#[fg=$thm_bg,bg=$thm_blue] #[fg=$thm_fg,bg=$thm_gray] $date_time "
#
#  # Right column 1 by default shows the Window name.
#  local right_column1=$show_window
#
#  # Right column 2 by default shows the current Session name.
#  local right_column2=$show_session
#
#  # Window status by default shows the current directory basename.
#  local window_status_format=$show_directory_in_window_status
#  local window_status_current_format=$show_directory_in_window_status_current
#
#  # NOTE: With the @catppuccin_window_tabs_enabled set to on, we're going to
#  # update the right_column1 and the window_status_* variables.
#  if [[ "$${wt_enabled}" == "on" ]]; then
#    right_column1=$show_directory
#    window_status_format=$show_window_in_window_status
#    window_status_current_format=$show_window_in_window_status_current
#  fi
#
#  if [[ "$${user}" == "on" ]]; then
#    right_column2=$right_column2$show_user
#  fi
#
#  if [[ "$${host}" == "on" ]]; then
#    right_column2=$right_column2$show_host
#  fi
#
#  if [[ "$${date_time}" != "off" ]]; then
#    right_column2=$right_column2$show_date_time
#  fi
#
#  set status-left ""
#
#  set status-right "$${right_column1},$${right_column2}"
#
#  setw window-status-format "$${window_status_format}"
#  setw window-status-current-format "$${window_status_current_format}"
#
#  # --------=== Modes
#  #
#  setw clock-mode-colour "$${thm_blue}"
#  setw mode-style "fg=$${thm_pink} bg=$${thm_black4} bold"
#
#  tmux "$${tmux_commands[@]}"
          set-option -g status-left "#[fg=${types.bg}]#[bg=${normal.blue}]#[bold]   #[fg=${normal.blue}]#[bg=default]"
          set-option -g status-bg default
          set-option -g status-right "#[italics,fg=${normal.blue},bg=default]#[fg=${types.bg},bg=${normal.blue}]#H | %b %d, %H:%M  #[fg=${types.bg},bg=${normal.blue},bold,italics] base-#S "

          # -------===[ Clock & Selection ]===------- #
          set-window-option -g clock-mode-colour "${types.border}"
          set-window-option -g mode-style "fg=${types.bg} bg=${types.highlight} bold"
        '';
    };
  };
}
