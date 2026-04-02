{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.modules) mkIf;
in
{
  options.modules.shell.toolset.scm =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "version-control systems";
    };

  config = mkIf config.modules.shell.toolset.scm.enable {
    user.packages = attrValues (
      {
        inherit (pkgs)
          act
          dura
          gitui
          lazygit
          sad
          ;
        inherit (pkgs) gh git-open;
        inherit (pkgs) lazyjj mergiraf diffnav;
      }
      // optionalAttrs config.modules.shell.gnupg.enable {
        inherit (pkgs) git-crypt;
      }
    );

    # Prevent x11 askPass prompt on git push:
    programs.ssh.askPassword = "";

    hm.programs.zsh.initContent = ''
      # -------===[ Helpful Git Fn's ]===------- #
      gitignore() {
        curl -s -o .gitignore https://gitignore.io/api/$1
      }
    '';

    hm.programs.fish.functions = {
      gitignore = "curl -sL https://www.gitignore.io/api/$argv";
    };

    hm.programs.delta =
      let
        inherit (config.modules.themes.colors.main) types normal bright;
      in
      {
        enable = true;
        # enableAutomaticGitIntegration = true;
        options = {
          decorations = {
            commit-decoration-style = "bold ${normal.yellow} box ${normal.red}";
            minus-style = "${normal.white} bold ul ${normal.red}";
            plus-style = "${normal.white} bold ul ${normal.green}";
            file-decoration-style = "none";
            file-style = "bold ${normal.yellow} ul";
          };
          features = "decorations";
          whitespace-error-style = "22 reverse";
        };
      };
    hm.programs.git =
      let
        inherit (config.modules.themes.colors.main) types normal bright;
      in
      {
        enable = true;
        package = pkgs.gitFull;
        # difftastic = {
        #   enable = true;
        #   background = "dark";
        #   color = "always";
        #   display = "inline";
        # };

        settings.alias = {
          unadd = "reset HEAD";

          # Data Analysis:
          ranked-authors = "!git authors | sort | uniq -c | sort -n";
          emails = ''
            !git log --format="%aE" | sort -u
          '';
          email-domains = ''
            !git log --format="%aE" | awk -F'@' '{print $2}' | sort -u
          '';
        };

        attributes = [
          "*.lisp diff=lisp"
          "*.el diff=lisp"
          "*.org diff=org"

          # mergiraf: syntax-aware merge driver
          "*.java merge=mergiraf"
          "*.rs merge=mergiraf"
          "*.go merge=mergiraf"
          "*.js merge=mergiraf"
          "*.jsx merge=mergiraf"
          "*.json merge=mergiraf"
          "*.yml merge=mergiraf"
          "*.yaml merge=mergiraf"
          "*.toml merge=mergiraf"
          "*.html merge=mergiraf"
          "*.htm merge=mergiraf"
          "*.xhtml merge=mergiraf"
          "*.xml merge=mergiraf"
          "*.c merge=mergiraf"
          "*.h merge=mergiraf"
          "*.cc merge=mergiraf"
          "*.cpp merge=mergiraf"
          "*.hpp merge=mergiraf"
          "*.cs merge=mergiraf"
          "*.dart merge=mergiraf"
          "*.py merge=mergiraf"
          "*.ts merge=mergiraf"
          "*.tsx merge=mergiraf"
          "*.nix merge=mergiraf"
          "*.hs merge=mergiraf"
          "*.scala merge=mergiraf"
          "*.lua merge=mergiraf"
          "*.rb merge=mergiraf"
          "*.sh merge=mergiraf"
        ];

        # for my git and flakes
        # "*.envrc"
        ignores = [
          # General:
          "*.bloop"
          "*.bsp"
          "*.direnv"
          "*.metals"
          "*.metals.sbt"
          "*metals.sbt"
          "*hie.yaml"
          "*.mill-version"
          "*.jvmopts"

          # Emacs:
          "*~"
          "*.*~"
          "\\#*"
          ".\\#*"

          # OS-related:
          ".DS_Store?"
          ".DS_Store"
          ".CFUserTextEncoding"
          ".Trash"
          ".Xauthority"
          "thumbs.db"
          "Thumbs.db"
          "Icon?"

          # Compiled residues:
          "*.class"
          "*.exe"
          "*.o"
          "*.pyc"
          "*.elc"

          # backups files:
          "*.orig"
          "*.swp"
          "*.swo"

          # Directories
          "node_modules"
          "dist"
          "__pycache__"

          # VCS
          ".jj/"

          # AI/Agent
          ".sisyphus"

          # scratch files
          "handoff_*.md"
        ];

        settings = {
          init.defaultBranch = "main";
          core = {
            editor = "nvim";
            whitespace = "trailing-space,space-before-tab";
          };
          pager = {
            diff = "diffnav";
          };
          branch = {
            sort = "-committerdate";
          };
          maintenance = {
            auto = false;
            strategy = "incremental";
          };

          column = {
            ui = "auto";
          };
          commit.gpgSign = false;
          # credential.helper = "${pkgs.gitFull}/bin/git-credential-libsecret";

          user = {
            name = "rolfst";
            email = "rolfst@gmail.com";
            signKey = "7CE0453D6767DBD1";
          };

          tag.gpgSign = true;
          pull.rebase = false;
          # push = {
          #   default = "current";
          #   gpgSign = "if-asked";
          #   autoSquash = true;
          # };

          github.user = "rolfst";
          gitlab.user = "rolfst";

          filter = {
            required = true;
            smudge = "git-lfs smudge -- %f";
            process = "git-lfs filter-process";
            clean = "git-lfs clean -- %f";
          };

          url = {
            "https://github.com/".insteadOf = "gh:";
            "git@github.com:".insteadOf = "ssh+gh:";
            "git@github.com:rolfst/".insteadOf = "gh:/";
            "https://gitlab.com/".insteadOf = "gl:";
            "https://gist.github.com/".insteadOf = "gist:";
            "https://bitbucket.org/".insteadOf = "bb:";
          };
          merge = {
            tool = "nvim";
            mergiraf = {
              name = "mergiraf";
              driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P";
            };
          };
          mergetool = {
            nvim = {
              cmd = "nvim -d -c \"wincmd l\" -c \"norm ]c\" \"$LOCAL\" \"$MERGED\" \"$REMOTE\"";
            };
            keepBackup = false;
          };

          diff = {
            "lisp".xfuncname =
              "^(((;;;+ )|\\(|([ 	]+\\(((cl-|el-patch-)?def(un|var|macro|method|custom)|gb/))).*)$";
            "org".xfuncname = "^(\\*+ +.*)$";
          };
        };
      };

    hm.programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "rolfst";
          email = "rolfst@gmail.com";
        };
        ui = {
          default-command = "log";
          diff-editor = ":builtin";
          merge-editor = "vimdiff";
          pager = "diffnav";
        };
        merge-tools.vimdiff = {
          program = "nvim";
          merge-args = [
            "-f" "-d" "$output" "-M"
            "$left" "$base" "$right"
            "-c" "wincmd J | wincmd ="
          ];
          merge-tool-edits-conflict-markers = true;
        };
        merge-tools.mergiraf = {
          program = "mergiraf";
          merge-args = [
            "jj"
            "$left"
            "$base"
            "$right"
            "-o"
            "$output"
          ];
        };
        git = {
          auto-local-bookmark = true;
        };
      };
    };
  };
}
