{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) toString;
  inherit (lib.modules) mkIf mkMerge;
  inherit (pkgs) python3 writeScriptBin;
in
{
  options.modules.desktop.terminal.kitty =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "GPU-accelerated terminal emulator";
    };

  config = mkIf config.modules.desktop.terminal.kitty.enable {
    user.packages = [
      pkgs.chafa
      pkgs.viu
      (writeScriptBin "kittysession-l" ''
            #!/usr/bin/env bash

            SESSION_DIR="$HOME/.local/share/kitty/sessions"
            WORKSPACE_DIR="$HOME/workspaces"
            mkdir -p "$SESSION_DIR"

            # ------------------------------------------------------------------
            # STAP 1: Verzamel bestaande Sessies
            # ------------------------------------------------------------------
            LIST_SESSIONS=$(find "$SESSION_DIR" -maxdepth 1 -type f -not -name '.*' | while read -r filepath; do
                filename=$(basename "$filepath")
                clean_name="''${filename%.*}"
                echo -e "  $clean_name (Sessie)\t$filepath"
            done)

            # ------------------------------------------------------------------
            # STAP 2: Verzamel Mappen
            # ------------------------------------------------------------------
            LIST_DIRS=$(${pkgs.fd}/bin/fd -td . "$WORKSPACE_DIR" \
                --min-depth 1 \
                --max-depth 3 \
                --exclude={node_modules,src,build,dist,bin,.git} | while read -r dirpath; do
                    echo -e "  $dirpath\t$dirpath"
                done)

            # ------------------------------------------------------------------
            # STAP 3: Selectie
            # ------------------------------------------------------------------
            SELECTION=$(echo -e "$LIST_SESSIONS\n$LIST_DIRS" | ${pkgs.fzf}/bin/fzf \
                --delimiter='\t' \
                --with-nth=1 \
                --height=40% \
                --reverse \
                --header="Selecteer Project of Sessie")

            if [ -z "$SELECTION" ]; then exit 0; fi

            TARGET_PATH=$(echo "$SELECTION" | cut -f2)

            # ------------------------------------------------------------------
            # STAP 4: Actie
            # ------------------------------------------------------------------

            if [ -f "$TARGET_PATH" ]; then
                # === GEVAL A: Bestaande sessie ===
                echo "Laden bestaande sessie..."
                kitten @ action goto_session "$TARGET_PATH"

            elif [ -d "$TARGET_PATH" ]; then
                # === GEVAL B: Directory -> Maak nieuwe sessie met TEMPLATE ===

                DIR_NAME=$(basename "$TARGET_PATH")
                NEW_SESSION_FILE="$SESSION_DIR/$DIR_NAME"

                if [ ! -f "$NEW_SESSION_FILE" ]; then
                    echo "Nieuwe sessie aanmaken met template: $DIR_NAME"

                    # Hier schrijven we jouw template naar het bestand.
                    # $TARGET_PATH wordt automatisch vervangen door de gekozen map.
                    cat > "$NEW_SESSION_FILE" <<EOF
        new_tab
        layout fat
        enabled_layouts fat,grid,horizontal,splits,stack,tall,vertical
        set_layout_state {"main_bias": [0.5, 0.5], "biased_map": {}, "opts": {"full_size": 1, "bias": 50, "mirrored": "n"}, "class": "Fat", "all_windows": {"active_group_idx": 0, "active_group_history": [1], "window_groups": [{"id": 1, "window_ids": [1]}]}}
        cd $TARGET_PATH
        launch 'kitty-unserialize-data={"id": 1}'
        focus

        focus_tab 0
        EOF
                else
                    echo "Sessiebestand bestond al ($DIR_NAME), wordt geladen..."
                fi

                # Laad de (nieuwe) file
                kitten @ action goto_session "$NEW_SESSION_FILE"
            fi
      '')
      # Het KS-RM (Remove) Script
      (writeScriptBin "kittysession-rm" ''
        SESSION_DIR="$HOME/.local/share/kitty/sessions"
        [ ! -d "$SESSION_DIR" ] && exit 0
        cd "$SESSION_DIR"

        SELECTION=$(find . -maxdepth 1 -type f -not -name '.*' | sed 's|^\./||' | while read -r file; do
            echo -e "''${file%.*}\t$file"
        done | ${pkgs.fzf}/bin/fzf -m --delimiter='\t' --with-nth=1 --height=40% --reverse --header="REMOVE SESSION(S)" --color=header:red | cut -f2)

        if [ -n "$SELECTION" ]; then
            echo "To be removed:"
            echo "$SELECTION"
            read -p "Confirm (y/N): " CONFIRM
            if [[ "$CONFIRM" =~ ^[yY]$ ]]; then
                echo "$SELECTION" | xargs rm
                echo "Removed."
            fi
        fi
      '')
      (writeScriptBin "ks-boot" ''
        SESSION_DIR="$HOME/.local/share/kitty/sessions"

        # Check of map bestaat
        if [ ! -d "$SESSION_DIR" ]; then echo "Geen sessiemap gevonden"; exit 1; fi

        # Maak een array van alle bestanden (gesorteerd)
        FILES=($(ls "$SESSION_DIR"/* | sort))

        if [ ''${#FILES[@]} -eq 0 ]; then echo "Geen sessies gevonden."; exit 1; fi

        # ---------------------------------------------------------
        # STAP 1: Start de EERSTE sessie (Master Window)
        # ---------------------------------------------------------
        FIRST_FILE="''${FILES[0]}"
        SOCKET_ADDR="unix:/tmp/kitty-boot-$$"

        echo "🚀 Master venster starten met: $FIRST_FILE"

        # We starten het nieuwe venster en geven het een socket
        kitty --session "$FIRST_FILE" --detach --listen-on "$SOCKET_ADDR"

        echo "Wachten op initialisatie..."
        while [ ! -S "/tmp/kitty-boot-$$" ]; do
            sleep 0.1
        done

        # ---------------------------------------------------------
        # STAP 2: Laad de OVERIGE files in dat nieuwe venster
        # ---------------------------------------------------------

        # Loop door de rest van de bestanden
        for ((i=1; i<''${#FILES[@]}; i++)); do
            FILE_PATH="''${FILES[$i]}"
            echo "📥 Inladen: $FILE_PATH"

            # Stuur goto_session commando naar de nieuwe socket
            kitten @ --to "$SOCKET_ADDR" action goto_session "$FILE_PATH"
        done

        # ---------------------------------------------------------
        # STAP 3: Sluit HUIDIG venster (De harde manier)
        # ---------------------------------------------------------
        echo "👋 Oude venster sluiten..."

        # We gebruiken 'kill' op de eigen PID.
        # Dit omzeilt de "Are you sure?" popup van Kitty.
        if [ -n "$KITTY_PID" ]; then
            kill "$KITTY_PID"
        else
            # Fallback voor als om de een of andere reden KITTY_PID leeg is
            # (Sluit netjes, maar riskeert popup)
            kitten @ action close-os-window
        fi
      '')
    ];

    hm.programs.kitty = {
      enable = true;
      package = pkgs.unstable.kitty;
      settings = {
        term = "xterm-kitty";

        sync_to_monitor = "yes";
        update_check_interval = 0;
        allow_remote_control = "yes";
        listen_on = "unix:@mykitty";
        close_on_child_death = "no";
        shell_integration = "no-cursor";
        confirm_os_window_close = -1;

        background_opacity = "0.8";
        dynamic_background_opacity = "yes";
        repaint_delay = 10;
        disable_ligatures = "cursor";
        adjust_line_height = "113%";
        inactive_text_alpha = "1.0";

        enable_audio_bell = "no";
        bell_on_tab = "no";
        visual_bell_duration = "0.0";

        strip_trailing_spaces = "smart";
        copy_on_select = "clipboard";
        select_by_word_characters = "@-./_~?&=%+#";
        clipboard_control = "write-clipboard write-primary no-append";

        default_pointer_shape = "beam";
        cursor_shape = "block";
        cursor_blink_interval = "0.5";
        cursor_stop_blinking_after = "15.0";

        input_delay = 3;
        pointer_shape_when_dragging = "beam";
        pointer_shape_when_grabbed = "arrow";

        click_interval = "0.5";
        mouse_hide_wait = "3.0";
        focus_follows_mouse = "yes";

        detect_urls = "yes";
        open_url_with = "default";
        url_prefixes = "http https file ftp gemini irc gopher mailto news git";

        scrollback_lines = 5000;
        wheel_scroll_multiplier = "5.0";

        initial_window_height = 28;
        initial_window_width = 96;
        remember_window_size = "yes";
        resize_draw_strategy = "static";

        window_border_width = "1.0";
        window_margin_width = "0.0";
        window_padding_width = "15.00";
        placement_strategy = "top-left";
        draw_minimal_borders = "yes";

        tab_bar_style = "custom";
        tab_separator = ''""'';
        tab_fade = "0 0 0 0";
        tab_activity_symbol = "none";
        tab_bar_edge = "top";
        tab_bar_margin_height = "0.0 0.0";
        active_tab_font_style = "bold-italic";
        inactive_tab_font_style = "normal";
        tab_bar_min_tabs = 1;
        tab_bar_filter = "session:current";
      };

      keybindings = {
        "ctrl+shift+end" = "load_config_file";
        "ctrl+shift+0" = "restore_font_size";
        "middle release ungrabbed" = "paste_from_selection";

        "ctrl+shift+t" = "new_tab_with_cwd";
        "ctrl+shift+/" = "new_window";

        "ctrl+shift+p" = "nth_window -1";
        "ctrl+shift+o" = "nth_window +1";
        "ctrl+left" = "neighboring_window left";
        "shift+left" = "move_window right";
        "ctrl+down" = "neighboring_window down";
        "shift+down" = "move_window up";
        "shift+alt+t" = "select_tab";

        "ctrl+shift+f5" =
          "save_as_session --use-foreground-process --base-dir=~/.local/share/kitty/sessions/";
        "ctrl+shift+f7" = "goto_session";
        "ctrl+shift+f8" = "close_session";
        "ctrl+shift+f10" = "close_os_window";

        # nvim hangs too often
        "ctrl+alt+k" = "launch --type=background sh -c 'pkill -u $(whoami) -x nvim'";
        # "ctrl+shift+f7>p" = "goto_session ~/.local/share/kitty";
        # "ctrl+shift+f7>-" = "goto_session -1";
      };

      extraConfig =
        let
          inherit (config.modules.themes) active;
        in
        mkIf (active != null) ''
          include ~/.config/kitty/config/${active}.conf
        '';
    };

    create.configFile =
      let
        inherit (config.modules.themes) active;
      in
      (mkMerge [
        {
          tab-bar = {
            target = "kitty/tab_bar.py";
            source = "${config.snowflake.configDir}/kitty/${active}-bar.py";
          };
        }

        (mkIf (active != null) {
          # TODO: Find ONE general nix-automation entry for VictorMono
          kitty-theme = {
            target = "kitty/config/${active}.conf";
            text =
              let
                inherit (config.modules.themes.colors.main) bright normal types;
                inherit (config.modules.themes.font.mono) size;
              in
              ''
                font_family               FiraCode Bold Nerd Font Complete
                italic_font               FiraCode Bold Italic Nerd Font Complete
                bold_font                 FiraCode SemiBold Nerd Font Complete
                bold_italic_font          FiraCode SemiBold Italic Nerd Font Complete
                font_size                 ${toString size}

                foreground                ${types.fg}
                background                ${types.bg}

                cursor                    ${normal.yellow}
                cursor_text_color         ${types.fg}

                tab_bar_background        ${types.bg}
                tab_title_template        "{fmt.fg._7976ab}{fmt.bg.default} ○ {index}:{f'{title[:6]}…{title[-6:]}' if title.rindex(title[-1]) + 1 > 25 else title}{' []' if layout_name == 'stack' else '''} "
                active_tab_title_template "{fmt.fg._f2cdcd}{fmt.bg.default}   綠{session_name}-{index}:{f'{title[:6]}…{title[-6:]}' if title.rindex(title[-1]) + 1 > 25 else title}{' []' if layout_name == 'stack' else '''} "

                selection_foreground      ${types.bg}
                selection_background      ${types.highlight}

                color0                    ${bright.black}
                color8                    ${bright.black}

                color1                    ${normal.red}
                color9                    ${bright.red}

                color2                    ${normal.green}
                color10                   ${bright.green}

                color3                    ${normal.yellow}
                color11                   ${bright.yellow}

                color4                    ${normal.blue}
                color12                   ${bright.blue}

                color5                    ${normal.magenta}
                color13                   ${bright.magenta}

                color6                    ${normal.cyan}
                color14                   ${bright.cyan}

                color7                    ${normal.white}
                color15                   ${normal.white}
              '';
          };
        })
      ]);
  };
}
