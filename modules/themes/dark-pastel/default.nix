{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) toString;
  inherit (lib) mkDefault mkIf mkMerge;

  cfg = config.modules.themes;
in {
  config = mkIf (cfg.active == "dark-pastel") (mkMerge [
    {
      modules.themes = {
        wallpaper = mkDefault ../rose-pine/assets/loaki-solarpunk.jpg;

        gtk = {
          name = "Adwaita-dark";
          package = pkgs.adwaita-icon-theme;
        };

        iconTheme = {
          name = "Fluent-dark";
          package =
            pkgs.fluent-icon-theme.override {colorVariants = ["green"];};
        };

        pointer = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
        };

        fontConfig = {
          packages = [
            pkgs.noto-fonts-color-emoji
            pkgs.nerd-fonts.fira-code
          ];
          mono = ["FiraCode Nerd Font Mono"];
          sans = ["FiraCode Nerd Font"];
          emoji = ["Noto Color Emoji"];
        };

        font = {
          mono.family = "FiraCode Nerd Font Mono";
          sans.family = "FiraCode Nerd Font";
        };

        colors = {
          main = {
            normal = {
              black = "#000000";
              red = "#ff5555";
              green = "#55ff55";
              yellow = "#ffff55";
              blue = "#5555ff";
              magenta = "#ff55ff";
              cyan = "#55ffff";
              white = "#bbbbbb";
            };
            bright = {
              black = "#555555";
              red = "#ff5555";
              green = "#55ff55";
              yellow = "#ffff55";
              blue = "#5555ff";
              magenta = "#ff55ff";
              cyan = "#55ffff";
              white = "#ffffff";
            };
            types = {
              fg = "#ffffff";
              bg = "#000000";
              panelbg = "#55ff55";
              border = "#5555ff";
              highlight = "#ff55ff";
            };
          };

          rofi = {
            bg = {
              main = "hsla(0, 0%, 0%, 1)";
              alt = "hsla(0, 0%, 0%, 0)";
              bar = "hsla(0, 0%, 10%, 1)";
            };
            fg = "hsla(0, 0%, 100%, 1)";
            ribbon = {
              outer = "hsla(120, 100%, 67%, 1)";
              inner = "hsla(240, 100%, 67%, 1)";
            };
            selected = "hsla(300, 100%, 67%, 1)";
            urgent = "hsla(0, 100%, 67%, 1)";
            transparent = "hsla(0, 0%, 0%, 0)";
          };
        };

        editor = {
          helix = {
            dark = "dark_plus";
            light = "onelight";
          };
          neovim = {
            dark = "default";
            light = "default";
          };
          vscode = {
            dark = "Default Dark+";
            light = "Default Light+";
            extension = {
              name = "";
              publisher = "";
              version = "";
              hash = "";
            };
          };
        };
      };
    }

    (mkIf config.services.xserver.enable {
      hm.programs.rofi = {
        extraConfig = {
          icon-theme = let inherit (cfg.iconTheme) name; in "${name}";
          font = let
            inherit (cfg.font.sans) family weight size;
          in "${family} ${weight} ${toString size}";
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
            text-color = mkLiteral "@bg";
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
        inherit (cfg.font.mono) family size weight;
      in {
        "custom_background_color " = "0.00 0.00 0.00";
        "custom_text_color " = "1.00 1.00 1.00";

        "text_highlight_color" = "1.00 1.00 1.00";
        "visual_mark_color" = "0.33 0.33 0.33 1.0";
        "search_highlight_color" = "1.00 0.33 0.33";
        "link_highlight_color" = "0.33 0.33 1.00";
        "synctex_highlight_color" = "0.33 1.00 0.33";

        "page_separator_width" = "2";
        "page_separator_color" = "0.73 0.73 0.73";
        "status_bar_color" = "0.10 0.10 0.10";

        "font_size" = "${toString size}";
        "ui_font" = "${family} ${weight}";
      };
    })

    (mkIf (config.modules.desktop.type == "x11") {
      services.xserver.displayManager = {
        lightdm.greeters.mini.extraConfig = let
          inherit (cfg.colors.main) normal types;
        in ''
          text-color = "${types.bg}"
          password-background-color = "${normal.black}"
          window-color = "${types.border}"
          border-color = "${types.border}"
        '';
      };
    })
  ]);
}
