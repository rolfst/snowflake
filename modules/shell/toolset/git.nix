{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.modules) mkIf;
in {
  options.modules.shell.toolset.git = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "version-control system";};

  config = mkIf config.modules.shell.toolset.git.enable {
    user.packages = attrValues ({
        inherit (pkgs) act dura gitui lazygit sad;
        inherit (pkgs.gitAndTools) gh git-open;
      }
      // optionalAttrs config.modules.shell.gnupg.enable {
        inherit (pkgs.gitAndTools) git-crypt;
      });

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

    hm.programs.git = let
      inherit (config.modules.themes.colors.main) types normal bright;
    in {
      enable = true;
      delta = {
        enable = true;
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
      package = pkgs.gitFull;
      # difftastic = {
      #   enable = true;
      #   background = "dark";
      #   color = "always";
      #   display = "inline";
      # };

      aliases = {
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

      attributes = ["*.lisp diff=lisp" "*.el diff=lisp" "*.org diff=org"];

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
      ];

      extraConfig = {
        init.defaultBranch = "main";
        core = {
          editor = "nvim";
          whitespace = "trailing-space,space-before-tab";
        };
        branch = {sort = "-committerdate";};
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
        };
        mergetool = {
          nvim = {
            cmd = "nvim -d -c \"wincmd l\" -c \"norm ]c\" \"$LOCAL\" \"$MERGED\" \"$REMOTE\"";
          };
          keepBackup = false;
        };

        diff = {
          "lisp".xfuncname = "^(((;;;+ )|\\(|([ 	]+\\(((cl-|el-patch-)?def(un|var|macro|method|custom)|gb/))).*)$";
          "org".xfuncname = "^(\\*+ +.*)$";
        };
      };
    };
  };
}
