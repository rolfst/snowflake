{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkForce getExe;
  inherit (lib.strings) concatStrings;
  inherit (lib.attrsets) mapAttrsToList;

  abbrevs = import "${config.snowflake.configDir}/shell-abbr";

  # Aliases that are safe as nushell aliases (simple command mappings)
  # Aliases whose commands conflict with nushell builtins (e.g. `watch`)
  nushellConflicts = [ "usbStat" ];

  simpleAbbrevs =
    let
      # Keys containing '!' are not valid nushell alias names — skip them
      isSimple =
        name: _:
        !(lib.strings.hasInfix "!" name)
        && !(lib.strings.hasInfix ";" (abbrevs.${name}))
        && !(lib.strings.hasInfix "|" (abbrevs.${name}))
        && !(lib.strings.hasInfix "$(" (abbrevs.${name}))
        && !(builtins.elem name nushellConflicts);
    in
    lib.filterAttrs isSimple abbrevs;

  # Aliases that need special handling (contain !, pipes, subshells, or semicolons)
  complexAbbrevs =
    let
      isComplex =
        name: _:
        (lib.strings.hasInfix "!" name)
        || (lib.strings.hasInfix ";" (abbrevs.${name}))
        || (lib.strings.hasInfix "|" (abbrevs.${name}))
        || (lib.strings.hasInfix "$(" (abbrevs.${name}));
    in
    lib.filterAttrs isComplex abbrevs;

  # Generate nushell def commands for complex aliases
  complexDefs = concatStrings (
    mapAttrsToList (
      name: cmd:
      let
        # Sanitize name: replace '!' with '_' for valid nushell identifiers
        safeName = builtins.replaceStrings [ "!" ] [ "_" ] name;
      in
      ''
        # Abbreviation: ${name}
        def "${safeName}" [] { ^bash -c ${lib.strings.escapeNixString cmd} }
      ''
    ) complexAbbrevs
  );
in
{
  config = mkIf (config.modules.shell.default == "nushell") {
    modules.shell.corePkgs.enable = true;

    # -------===[ Exec Strategy ]===------- #
    # Nushell is NOT POSIX-compatible and cannot source /etc/profile.
    # We keep zsh as the login shell so NixOS environment setup runs correctly,
    # then exec nushell for interactive use.
    users.defaultUserShell = mkForce pkgs.zsh;
    environment.shells = [
      pkgs.zsh
      pkgs.nushell
    ];

    # Enable zsh as login shell (minimal config — just enough to exec nu)
    programs.zsh.enable = true;
    environment.pathsToLink = [ "/share/zsh" ];

    hm.programs.zsh = {
      enable = true;
      dotDir = "${config.home.homeDirectory}/.config/zsh";

      initContent = ''
        # Exec nushell for interactive sessions.
        # Conditions:
        #   - Not a dumb terminal (e.g. scp, rsync)
        #   - Not running a bash-command-string (e.g. nix-shell)
        #   - Only when this is an interactive top-level shell
        if [[ "$TERM" != "dumb" && -z "$ZSH_EXECUTION_STRING" && -z "$NUSHELL_ACTIVE" ]]; then
          export NUSHELL_ACTIVE=1
          exec ${getExe pkgs.nushell}
        fi
      '';
    };

    # -------===[ Starship ]===------- #
    modules.shell.starship.enable = true;
    hm.programs.starship.enableNushellIntegration = true;

    # -------===[ Zoxide ]===------- #
    hm.programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    # -------===[ Direnv ]===------- #
    hm.programs.direnv.enableNushellIntegration = true;

    # -------===[ Nushell (home-manager) ]===------- #
    hm.programs.nushell = {
      enable = true;

      settings = {
        show_banner = false;
        edit_mode = "vi";
        table.mode = "rounded";
        completions = {
          case_sensitive = false;
          quick = false;
          partial = true;
          external = {
            enable = true;
            max_results = 100;
          };
        };
        cursor_shape = {
          vi_insert = "line";
          vi_normal = "block";
        };
        history = {
          max_size = 10000;
          sync_on_enter = true;
          file_format = "sqlite";
        };
        rm.always_trash = false;
        use_ansi_coloring = true;
      };

      shellAliases =
        let
          # Aliases inherited from bash.nix via home-manager's shellAliases merging
          # that must be excluded so nushell builtins are preserved.
          bashLeaks = [
            "ls"
            "lsa"
            "wup"
            "wud"
          ];

          merged = {
            # -------===[ Core ]===------- #
            eza = "eza --group-directories-first";
            less = "less -R";

            # -------===[ Develop: Python ]===------- #
            py = "python";
            ipy = "ipython --no-banner";
            ipylab = "ipython --pylab=qt5 --no-banner";

            # -------===[ Develop: Rust ]===------- #
            rs = "rustc";
            ca = "cargo";

            # -------===[ Develop: Node ]===------- #
            ya = "yarn";
          }
          // simpleAbbrevs;
        in
        lib.mkForce (builtins.removeAttrs merged bashLeaks);

      extraConfig = ''
        # -------===[ Man-page Colors ]===------- #
        $env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"
        $env.MANROFFOPT = "-c"

        # -------===[ Complex Aliases (need bash for POSIX syntax) ]===------- #
        ${complexDefs}

        # -------===[ Nushell Builtin Overrides ]===------- #
        # `watch` is a nushell builtin; use `^watch` to call the external binary
        alias usbStat = ^watch rg -e Dirty: -e Writeback: /proc/meminfo

        # -------===[ Develop: Node (POSIX PATH manipulation) ]===------- #
        def n [] { ^bash -c "PATH=\"$(npm bin):$PATH\" $@" }

        # -------===[ Virtualize: Podman ]===------- #
        alias pps = podman ps --format "table {{ .Names }}\t{{ .Status }}" --sort names
        def pclean [] { ^bash -c "podman ps -a | grep -v 'CONTAINER\\|_config\\|_data\\|_run' | cut -c-12 | xargs podman rm 2>/dev/null" }
        def piclean [] { ^bash -c "podman images | grep '<none>' | grep -P '[1234567890abcdef]{12}' -o | xargs -L1 podman rmi 2>/dev/null" }

        # -------===[ Useful Functions ]===------- #
        def la [path?: string] {
          let target = if ($path | is-empty) { "." } else { $path | path expand }
          ls -al $target | select name type modified mode user group size
            | each {|row| $row | merge { sort_key: (if $row.type == "dir" { "0" } else { "1" }) }}
            | sort-by sort_key name
            | reject sort_key
        }
        def sysup [] {
          nixos-rebuild switch --sudo --flake $".#(hostname)"
        }

        def mcdir [...dirs: string] {
          let target = ($dirs | last)
          mkdir ...$dirs
          cd $target
        }

        def gwa [path: string, remote: string, branch: string] {
          git worktree add $path $remote -b $branch
        }

        def gwr [...args: string] {
          git worktree remove ...$args
        }

        # -------===[ Kitty Session Keybindings ]===------- #
        $env.config.keybindings ++= [
          {
            name: kitty_session_launcher
            modifier: control
            keycode: char_l
            mode: [vi_insert vi_normal]
            event: {
              send: executehostcommand
              cmd: "kittysession-l"
            }
          }
          {
            name: kitty_session_remove
            modifier: control
            keycode: char_d
            mode: [vi_insert vi_normal]
            event: {
              send: executehostcommand
              cmd: "kittysession-rm"
            }
          }
          {
            name: kitty_session_boot
            modifier: control
            keycode: char_b
            mode: [vi_insert vi_normal]
            event: {
              send: executehostcommand
              cmd: "ks-boot"
            }
          }
        ]
      '';

      environmentVariables = {
        EDITOR = "nvim";
      };
    };

    # -------===[ Carapace (completions engine) ]===------- #
    hm.programs.carapace = {
      enable = true;
      enableNushellIntegration = true;
    };
  };
}
