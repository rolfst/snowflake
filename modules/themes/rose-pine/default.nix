{
  options,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) toString readFile;
  inherit (lib) attrValues concatMapStringsSep mkDefault mkIf mkMerge;

  cfg = config.modules.themes;
  configDir = config.snowflake.configDir;
in {
  config = mkIf (cfg.active == "rose-pine") (mkMerge [
    {
      modules.themes = {
        wallpaper = mkDefault ./assets/loaki-solarpunk.jpg;
        gtk = {
          name = "rose-pine";
          package = pkgs.rose-pine-gtk-theme;
          # package = pkgs.my.rose-pine-gtk;
        };

        iconTheme = {
          name = "rose-pine";
          package = pkgs.rose-pine-icon-theme;
        };

        pointer = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
        };

        fontConfig = {
          packages = attrValues {
            inherit (pkgs) cascadia-code noto-fonts-emoji sarasa-gothic;
            nerdfonts =
              pkgs.nerdfonts.override {fonts = ["Arimo" "FiraCode"];};
          };
          sans = ["FiraCode Nerd Font" "Cascadia Code" "Sarasa Mono SC"];
          mono = ["FiraCode Nerd Font Mono" "Sarasa Gothic SC"];
          emoji = ["Noto Color Emoji"];
        };

        font = {
          mono.family = "FiraCode Nerd Font";
          sans.family = "Arimo Nerd Font";
        };

        symbols = {
          characters = {
            vicmd = "";
            github = " ";
            folder = " ";
            duration = " ";
            battery = "🔋";
            charging = "⚡️";
            discharging = "💀";
          };
          decorators = {
            left_separator = "";
            right_separator = "";
            error = "";
            success = "";
            warning = "";
          };
        };
        colors = {
          main = {
            normal = {
              black = "#26233a";
              red = "#eb6f92";
              green = "#31748f";
              yellow = "#f6c177";
              blue = "#9ccfd8";
              magenta = "#c4a7e7";
              cyan = "#ebbcba";
              white = "#e0def4";
            };
            bright = {
              black = "#6e6a86";
              red = "#eb6f92";
              green = "#31748f";
              yellow = "#c4a7e7";
              blue = "#21202e";
              magenta = "#c4a7e7";
              cyan = "#ebbcba";
              white = "#e0def4";
            };
            types = {
              fg = "#e0def4";
              bg = "#191724";
              panelbg = "#26233a";
              border = "#31748f";
              highlight = "#c5b1e5";
              inactive = "#19172";
            };
          };

          rofi = {
            colors = {
              bg = "hsla(249, 22%, 12%, 1)";
              cur = "hsla(247, 23%, 15%, 1)";
              fgd = "hsla(245, 50%, 91%, 1)";
              cmt = "hsla(249, 12%, 47%, 1)";
              cya = "hsla(189, 43%, 73%, 1)";
              grn = "hsla(197, 49%, 38%, 1)";
              ora = "hsla(2, 55%, 83%, 1)";
              pur = "hsla(267, 57%, 78%, 1)";
              red = "hsla(343, 76%, 68%, 1)";
              yel = "hsla(35, 88%, 72%, 1)";
            };
            bg = {
              main = "hsla(249, 22%, 12%, 1)";
              alt = "hsla(247, 23%, 15%, 0)";
              bar = "hsla(248, 25%, 18%, 1)";
            };
            fg = "hsla(245, 52%, 91%, 1)";
            ribbon = {
              outer = "hsla(188, 68%, 27%, 1)";
              inner = "hsla(202, 76%, 24%, 1)";
            };
            selected = "hsla(197, 49%, 38%, 1)";
            urgent = "hsla(343, 76%, 68%, 1)";
            transparent = "hsla(0, 0%, 0%, 0)";
          };
        };

        editor = {
          neovim = {
            dark = "rose-pine-moon";
            light = "rose-pine-dawn"; # TODO: vim.g.tokyonight_style = "day"
          };
          vscode = {
            dark = "rose-pine";
            light = "rose-pine-moon";
            # extension = {
            #   name = "rose-pine";
            #   publisher = "mvllow";
            #   version = "2.9.0 ";
            #   hash = "";
            # };
          };
        };
      };
    }

    # (mkIf config.modules.desktop.browsers.firefox.enable {
    #   modules.desktop.browsers.firefox.userChrome =
    #     concatMapStringsSep "\n" readFile
    #     [ "${configDir}/firefox/vertical-tabs.css" ];
    # })
    # (mkIf config.modules.desktop.browsers.firefox.enable {
    #   modules.desktop.browsers.firefox.userChrome = let
    #     usrChromeDir = "${config.snowflake.configDir}/firefox/userChrome";
    #   in
    #     concatMapStringsSep "\n" readFile [
    #       "${usrChromeDir}/treestyle-tabs.css"
    #     ];
    # })

    (mkIf config.services.xserver.enable {
      hm.programs.rofi = {
        extraConfig = {
          icon-theme = let inherit (cfg.iconTheme) name; in "${name}";
          font = let
            inherit (cfg.font) mono sans;
          in "${mono.family} Italic ${mono.weight} ${toString sans.size}";
        };

        theme = let
          inherit (config.hm.lib.formats.rasi) mkLiteral;
          inherit (cfg.colors.rofi) bg fg ribbon selected transparent urgent;
        in {
          "*" = {
            fg = mkLiteral "${fg}";
            bg = mkLiteral "${bg.main}";
            bg-alt = mkLiteral "${bg.alt}";
            bg-bar = mkLiteral "${bg.bar}";

            outer-ribbon = mkLiteral "${ribbon.outer}";
            inner-ribbon = mkLiteral "${ribbon.inner}";
            selected = mkLiteral "${selected}";
            urgent = mkLiteral "${urgent}";
            transparent = mkLiteral "${transparent}";
          };

          "window" = {
            transparency = "real";
            background-color = mkLiteral "@bg";
            text-color = mkLiteral "@fg";
            border = mkLiteral "0% 0% 0% 1.5%";
            border-color = mkLiteral "@outer-ribbon";
            border-radius = mkLiteral "0% 0% 0% 2.5%";
            height = mkLiteral "54.50%";
            width = mkLiteral "43%";
            location = mkLiteral "center";
            x-offset = 0;
            y-offset = 0;
          };

          "prompt" = {
            enabled = true;
            padding = mkLiteral "0% 1% 0% 0%";
            background-color = mkLiteral "@bg-bar";
            text-color = mkLiteral "@fg";
          };

          "entry" = {
            background-color = mkLiteral "@bg-bar";
            text-color = mkLiteral "@fg";
            placeholder-color = mkLiteral "@fg";
            expand = true;
            horizontal-align = 0;
            placeholder = "Search";
            padding = mkLiteral "0.15% 0% 0% 0%";
            blink = true;
          };

          "inputbar" = {
            children = mkLiteral "[ prompt, entry ]";
            background-color = mkLiteral "@bg-bar";
            text-color = mkLiteral "@fg";
            expand = false;
            border = mkLiteral "0% 0% 0.3% 0.2%";
            border-radius = mkLiteral "1.5% 1.0% 1.5% 1.5%";
            border-color = mkLiteral "@inner-ribbon";
            margin = mkLiteral "0% 17% 0% 0%";
            padding = mkLiteral "1%";
            position = mkLiteral "center";
          };

          "listview" = {
            background-color = mkLiteral "@bg";
            columns = 5;
            spacing = mkLiteral "1%";
            cycle = false;
            dynamic = true;
            layout = mkLiteral "vertical";
          };

          "mainbox" = {
            background-color = mkLiteral "@bg";
            border = mkLiteral "0% 0% 0% 1.5%";
            border-radius = mkLiteral "0% 0% 0% 2.5%";
            border-color = mkLiteral "@inner-ribbon";
            children = mkLiteral "[ inputbar, listview ]";
            spacing = mkLiteral "3%";
            padding = mkLiteral "2.5% 2% 2.5% 2%";
          };

          "element" = {
            background-color = mkLiteral "@bg-bar";
            text-color = mkLiteral "@fg";
            orientation = mkLiteral "vertical";
            border-radius = mkLiteral "1.5% 1.0% 1.5% 1.5%";
            padding = mkLiteral "2% 0% 2% 0%";
          };

          "element-icon" = {
            background-color = mkLiteral "@transparent";
            text-color = mkLiteral "inherit";
            horizontal-align = "0.5";
            vertical-align = "0.5";
            size = mkLiteral "64px";
            border = mkLiteral "0px";
          };

          "element-text" = {
            background-color = mkLiteral "@transparent";
            text-color = mkLiteral "inherit";
            expand = true;
            horizontal-align = mkLiteral "0.5";
            vertical-align = mkLiteral "0.5";
            margin = mkLiteral "0.5% 1% 0% 1%";
          };

          "element normal.urgent, element alternate.urgent" = {
            background-color = mkLiteral "@urgent";
            text-color = mkLiteral "@fg";
            border-radius = mkLiteral "1%";
          };

          "element normal.active, element alternate.active" = {
            background-color = mkLiteral "@bg-alt";
            text-color = mkLiteral "@fg";
          };

          "element selected" = {
            background-color = mkLiteral "@selected";
            text-color = mkLiteral "@fg";
            border = mkLiteral "0% 0% 0.3% 0.2%";
            border-radius = mkLiteral "1.5% 1.0% 1.5% 1.5%";
            border-color = mkLiteral "@inner-ribbon";
          };

          "element selected.urgent" = {
            background-color = mkLiteral "@urgent";
            text-color = mkLiteral "@fg";
          };

          "element selected.active" = {
            background-color = mkLiteral "@bg-alt";
            color = mkLiteral "@fg";
          };
        };
      };

      hm.programs.sioyek.config = let
        inherit (cfg.font) mono sans;
      in {
        "custom_background_color " = "0.10 0.11 0.15";
        "custom_text_color " = "0.75 0.79 0.96";

        "text_highlight_color" = "0.24 0.35 0.63";
        "visual_mark_color" = "1.00 0.62 0.39 1.0";
        "search_highlight_color" = "0.97 0.46 0.56";
        "link_highlight_color" = "0.48 0.64 0.97";
        "synctex_highlight_color" = "0.62 0.81 0.42";

        "page_separator_width" = "2";
        "page_separator_color" = "0.81 0.79 0.76";
        "status_bar_color" = "0.34 0.37 0.54";

        "font_size" = "${toString sans.size}";
        "ui_font" = "${mono.family} ${mono.weight}";
      };
    })
  ]);
}
