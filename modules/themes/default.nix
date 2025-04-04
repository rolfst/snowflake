{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) getEnv map;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.strings) concatStringsSep optionalString removePrefix;

  cfg = config.modules.themes;
  desktop = config.modules.desktop;
in {
  options.modules.themes = let
    inherit (lib.options) mkOption mkPackageOption;
    inherit (lib.types) attrsOf int lines listOf nullOr path package str;
    inherit (lib.my) mkOpt toFilteredImage;
  in {
    active = mkOption {
      type = nullOr str;
      default = null;
      apply = v: let
        theme = getEnv "THEME";
      in
        if theme != ""
        then theme
        else v;
      description = ''
        Name of the theme which ought to be applied.
        Can be overridden by the `THEME` environment variable.
      '';
    };

    wallpaper = mkOpt (nullOr path) null;

    loginWallpaper = mkOpt (nullOr path) (
      if cfg.wallpaper != null
      then toFilteredImage cfg.wallpaper "-gaussian-blur 0x2 -modulate 70 -level 5%"
      else null
    );

    gtk = {
      name = mkOpt str "";
      package = mkPackageOption pkgs "gtk" {};
    };

    iconTheme = {
      name = mkOpt str "";
      package = mkPackageOption pkgs "icon" {};
    };

    pointer = {
      name = mkOpt str "";
      package = mkPackageOption pkgs "pointer" {};
      size = mkOpt int 24;
    };

    onReload = mkOpt (attrsOf lines) {};

    fontConfig = {
      packages = mkOpt (listOf package) [];
      mono = mkOpt (listOf str) [""];
      sans = mkOpt (listOf str) [""];
      emoji = mkOpt (listOf str) [""];
    };

    font = {
      mono = {
        family = mkOpt str "";
        weight = mkOpt str "SemiBold";
        weightAlt = mkOpt str "DemiBold";
        weightNum = mkOpt str "600";
        size = mkOpt int 13;
      };
      sans = {
        family = mkOpt str "";
        weight = mkOpt str "SemiBold";
        weightAlt = mkOpt str "DemiBold";
        weightNum = mkOpt str "600";
        size = mkOpt int 10;
      };
    };

    symbols = {
      characters = {
        vicmd = mkOpt str "";
        github = mkOpt str " ";
        folder = mkOpt str " ";
        duration = mkOpt str " ";
        battery = mkOpt str "🔋";
        charging = mkOpt str "⚡️";
        discharging = mkOpt str "💀";
      };
      decorators = {
        left_separator = mkOpt str "";
        right_separator = mkOpt str "";
        error = mkOpt str "";
        success = mkOpt str "";
        warning = mkOpt str "";
      };
    };

    colors = {
      main = {
        normal = {
          black = mkOpt str "#000000"; # 0
          red = mkOpt str "#FF0000"; # 1
          green = mkOpt str "#00FF00"; # 2
          yellow = mkOpt str "#FFFF00"; # 3
          blue = mkOpt str "#0000FF"; # 4
          magenta = mkOpt str "#FF00FF"; # 5
          cyan = mkOpt str "#00FFFF"; # 6
          white = mkOpt str "#BBBBBB"; # 7
        };
        bright = {
          black = mkOpt str "#888888"; # 8
          red = mkOpt str "#FF8800"; # 9
          green = mkOpt str "#00FF80"; # 10
          yellow = mkOpt str "#FF8800"; # 11
          blue = mkOpt str "#0088FF"; # 12
          magenta = mkOpt str "#FF88FF"; # 13
          cyan = mkOpt str "#88FFFF"; # 14
          white = mkOpt str "#FFFFFF"; # 15
        };
        types = let
          inherit (cfg.colors.main.normal) black red white yellow;
          inherit (cfg.colors.main.types) bg fg;
        in {
          bg = mkOpt str black;
          fg = mkOpt str white;
          panelbg = mkOpt str bg;
          panelfg = mkOpt str fg;
          border = mkOpt str bg;
          error = mkOpt str red;
          warning = mkOpt str yellow;
          highlight = mkOpt str white;
          inactive = mkOpt str "#19172";
        };
      };

      fishColor = hexColor: removePrefix "#" hexColor;

      rofi = {
        colors = {
          bg = mkOpt str "hsla(249, 22%, 12%, 1)";
          cur = mkOpt str "hsla(247, 23%, 15%, 1)";
          fgd = mkOpt str "hsla(245, 50%, 91%, 1)";
          cmt = mkOpt str "hsla(249, 12%, 47%, 1)";
          cya = mkOpt str "hsla(189, 43%, 73%, 1)";
          grn = mkOpt str "hsla(197, 49%, 38%, 1)";
          ora = mkOpt str "hsla(2, 55%, 83%, 1)";
          pur = mkOpt str "hsla(267, 57%, 78%, 1)";
          red = mkOpt str "hsla(343, 76%, 68%, 1)";
          yel = mkOpt str "hsla(35, 88%, 72%, 1)";
        };
        bg = {
          main = mkOpt str "#FFFFFF";
          alt = mkOpt str "#FFFFFF";
          bar = mkOpt str "#FFFFFF";
        };
        fg = mkOpt str "#FFFFFF";
        ribbon = {
          outer = mkOpt str "#FFFFFF";
          inner = mkOpt str "#FFFFFF";
        };
        selected = mkOpt str "#FFFFFF";
        urgent = mkOpt str "#FFFFFF";
        transparent = mkOpt str "#FFFFFF";
      };
    };

    editor = {
      helix = {
        light = mkOpt str "";
        dark = mkOpt str "";
      };
      neovim = {
        light = mkOpt str "";
        dark = mkOpt str "";
      };
      vscode = {
        dark = mkOpt str "";
        light = mkOpt str "";
        extension = {
          name = mkOpt str "";
          publisher = mkOpt str "";
          version = mkOpt str "";
          hash = mkOpt str "";
        };
      };
    };
  };

  config = mkIf (cfg.active != null) (mkMerge [
    {
      # Allow HM to control GTK Theme:
      programs.dconf.enable = true;

      hm.gtk = {
        enable = true;
        font = let
          inherit (cfg.font.sans) family size;
        in {
          name = family;
          size = size;
        };
        theme = let
          inherit (cfg.gtk) name package;
        in {
          name = name;
          package = package;
        };
        iconTheme = let
          inherit (cfg.iconTheme) name package;
        in {
          name = name;
          package = package;
        };
        gtk3.bookmarks = map (dir: "file://${config.user.home}/" + dir) [
          "snowflake"
          "notes"
        ];
        gtk4.extraConfig = {
          gtk-cursor-blink = false;
          # gtk-recent-files-limit = 20;
        };
      };

      home.pointerCursor = let
        inherit (cfg.pointer) name package size;
      in {
        name = name;
        package = package;
        size = size;
        gtk.enable = true;
      };

      fonts = let
        inherit (cfg.fontConfig) packages emoji mono sans;
      in {
        packages = packages;
        fontconfig.defaultFonts = {
          monospace = mono;
          sansSerif = sans;
          emoji = emoji;
        };
      };

      # hm.programs.vscode.extensions = let
      #   inherit (cfg.editor.vscode.extension) name publisher version hash;
      # in
      #   pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      #     {
      #       name = "${name}";
      #       publisher = "${publisher}";
      #       version = "${version}";
      #       hash = "${hash}";
      #     }
      #   ];
    }

    (mkIf (desktop.type == "wayland") {
      programs.regreet.settings.GTK = let
        inherit (cfg) pointer font iconTheme gtk;
      in {
        cursor_theme_name = "${pointer.name}";
        font_name = "${font.mono.family}";
        icon_theme_name = "${iconTheme.name}";
        theme_name = "${gtk.name}";
      };
    })

    (mkIf (desktop.type == "x11") (mkMerge [
      {
        # Read xresources files in ~/.config/xtheme/* to allow modular configuration
        # of Xresources.
        modules.themes.onReload.xtheme = ''
          cat "$XDG_CONFIG_HOME"/xtheme/* | ${getExe pkgs.xorg.xrdb} -load
        '';

        create.configFile = {
          xtheme-init = {
            target = "xtheme.init";
            text = cfg.onReload.xtheme;
            executable = true;
          };

          xtheme-definitions = {
            target = "xtheme/00-init";
            text = let
              inherit (cfg.colors.main) bright normal types;
            in ''
              #define bg   ${types.bg}
              #define fg   ${types.fg}
              #define blk  ${normal.black}
              #define bblk ${bright.black}
              #define red  ${normal.red}
              #define bred ${bright.red}
              #define grn  ${normal.green}
              #define bgrn ${bright.green}
              #define ylw  ${normal.yellow}
              #define bylw ${bright.yellow}
              #define blu  ${normal.blue}
              #define bblu ${bright.blue}
              #define mag  ${normal.magenta}
              #define bmag ${bright.magenta}
              #define cyn  ${normal.cyan}
              #define bcyn ${bright.cyan}
              #define wht  ${normal.white}
              #define bwht ${bright.white}
            '';
          };

          xtheme-colors = {
            target = "xtheme/05-colors";
            text = ''
              *.foreground: fg
              *.background: bg
              *.color0:  blk
              *.color1:  red
              *.color2:  grn
              *.color3:  ylw
              *.color4:  blu
              *.color5:  mag
              *.color6:  cyn
              *.color7:  wht
              *.color8:  bblk
              *.color9:  bred
              *.color10: bgrn
              *.color11: bylw
              *.color12: bblu
              *.color13: bmag
              *.color14: bcyn
              *.color15: bwht
            '';
          };

          xtheme-fonts = {
            target = "xtheme/05-fonts";
            text = let
              inherit (cfg.font.mono) family size weight;
            in ''
              *.font: xft:${family}:style=${weight}:pixelsize=${toString size}
              Emacs.font: ${family}:style=${weight}:pixelsize=${toString size}
            '';
          };

          xtheme-cursor = {
            target = "xtheme/06-cursor";
            text = let
              inherit (cfg.pointer) name size;
            in ''
              Xcursor.name: left_ptr
              Xcursor.size: ${toString size}
              Xcursor.theme: ${name}
            '';
          };
        };

        home.pointerCursor.x11 = {
          enable = true;
          defaultCursor = "left_ptr";
        };
      }

      # Change the wallpaper of our lightdm:
      (mkIf (cfg.loginWallpaper != null) {
        services.xserver.displayManager = {
          lightdm.background = cfg.loginWallpaper;
        };
      })

      # Auto-set wallpaper to prevent $HOME pollution!
      (mkIf (cfg.wallpaper != null) (let
        wCfg = config.services.xserver.desktopManager.wallpaper;
        command = ''
          if [ -e "$XDG_DATA_HOME/wallpaper" ]; then
            ${getExe pkgs.feh} --bg-${wCfg.mode} \
            ${optionalString wCfg.combineScreens "--no-xinerama"} \
            --no-fehbg \
            $XDG_DATA_HOME/wallpaper
          fi
        '';
      in {
        services.xserver.displayManager.sessionCommands = command;
        modules.themes.onReload.wallpaper = command;

        create.dataFile =
          mkIf (cfg.wallpaper != null) {"wallpaper".source = cfg.wallpaper;};
      }))

      (mkIf (cfg.loginWallpaper != null) {
        programs.regreet.settings.background = {
          path = cfg.loginWallpaper;
          fit = "Fill";
        };
      })

      (mkIf (cfg.onReload != {}) (let
        reloadTheme = let
          inherit (pkgs) stdenv writeScriptBin;
        in (writeScriptBin "reloadTheme" ''
          #!${stdenv.shell}
          echo "Reloading current theme: ${cfg.active}"
          ${concatStringsSep "\n" (mapAttrsToList (name: script: ''
              echo "[${name}]"
              ${script}
            '')
            cfg.onReload)}
        '');
      in {
        user.packages = [reloadTheme];
        system.userActivationScripts.reloadTheme = ''
          [ -z "$NORELOAD" ] && ${reloadTheme}/bin/reloadTheme
        '';
      }))
    ]))
  ]);
}
