{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  cfg = config.modules.shell;
in
{
  options.modules.shell =
    let
      inherit (lib.options) mkOption mkEnableOption;
      inherit (lib.types) nullOr enum;
    in
    {
      default = mkOption {
        type = nullOr (enum [
          "fish"
          "zsh"
          "xonsh"
          "nushell"
        ]);
        default = null;
        description = "Default system shell";
      };
      corePkgs.enable = mkEnableOption "core shell packages";
    };

  config = mkMerge [
    (mkIf (cfg.default != null) {
      users.defaultUserShell = pkgs."${cfg.default}";
    })

    (mkIf cfg.corePkgs.enable {
      modules.shell.toolset.btop.enable = true;

      hm.programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        config.whitelist.prefix = [ "/home" ];
      };

      hm.programs.yazi = {
        enable = true;
        # enableZshItegration = true;
        # enableBashIntegration = true;
        # enableNushellIntegration = true;
        plugins = {
          inherit (pkgs.yaziPlugins)
            mount
            sudo
            lazygit
            compress
            ;
        };

        keymap = {
          mgr.prepend_keymap = [
            {
              on = [
                "o"
                "c"
              ];
              run = "shell 'kitty @ launch --type=tab --tab-title opencode --cwd=\"$PWD\" opencode' --orphan";
              desc = "Open opencode in new kitty window";
            }
            {
              on = [
                "o"
                "j"
              ];
              run = "shell 'kitty @ launch --type=tab --tab-title lazyjj --cwd=\"$PWD\" lazyjj' --orphan";
              desc = "Open lazyjj in new kitty window";
            }
            {
              on = [
                "c"
                "a"
                "a"
              ];
              run = "plugin compress";
              desc = "Archive selected files";
            }
            {
              on = [
                "c"
                "a"
                "p"
              ];
              run = "plugin compress -p";
              desc = "Archive selected files (password)";
            }
            {
              on = [
                "c"
                "a"
                "h"
              ];
              run = "plugin compress -ph";
              desc = "Archive selected files (password+header)";
            }
            {
              on = [
                "c"
                "a"
                "l"
              ];
              run = "plugin compress -l";
              desc = "Archive selected files (compression level)";
            }
            {
              on = [
                "c"
                "a"
                "u"
              ];
              run = "plugin compress -phl";
              desc = "Archive selected files (password+header+level)";
            }
          ];
        };
      };

      user.packages = attrValues {
        yz = pkgs.yazi.override { _7zz = pkgs._7zz-rar; };
        inherit (pkgs)
          any-nix-shell
          pwgen
          yt-dlp
          csview
          ripdrag
          lsof
          file
          zoxide
          ;

        # GNU Alternatives
        inherit (pkgs)
          bat
          eza
          fd
          ;
        rgFull = pkgs.ripgrep.override { withPCRE2 = true; };
      };
    })
  ];
}
