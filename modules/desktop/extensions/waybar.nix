{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.desktop.extensions.waybar;
  inherit (config.modules.themes.colors.main) bright normal types;
in
{
  options.modules.desktop.extensions.waybar = {
    enable = mkEnableOption "status-bar for wayland";
  };

  config = mkIf cfg.enable {
    # Allow tray-icons to be displayed:
    hm.services.status-notifier-watcher.enable = true;

    hm.programs.waybar = {
      enable = false;
      settings = [
        {
          "layer" = "top";
          "position" = "top";
          modules-left = [
            "custom/launcher"
            "wlr/workspaces"
            "temperature"
            "idle_inhibitor"
            "mpd"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "custom/noctalia-recorder"
            "custom/noctalia-clipper"
            "custom/noctalia-notes"
            "custom/noctalia-todo"
            "custom/noctalia-cheatsheet"
            "custom/noctalia-assistant"
            "memory"
            "cpu"
            "network"
            "battery"
            "custom/powermenu"
            "tray"
          ];
          "custom/launcher" = {
            "format" = " ";
            "on-click" = "rofi -no-lazy-grab -show drun -modi drun";
            "tooltip" = false;
          };

          "custom/noctalia-recorder" = {
            "format" = " ";
            "on-click" = "noctalia-shell ipc call plugin:screen-recorder toggle";
            "tooltip" = true;
            "tooltip-format" = "Screen Recorder";
          };
          "custom/noctalia-clipper" = {
            "format" = " ";
            "on-click" = "noctalia-shell ipc call plugin:clipper toggle";
            "tooltip" = true;
            "tooltip-format" = "Clipboard Manager";
          };
          "custom/noctalia-notes" = {
            "format" = " ";
            "on-click" = "noctalia-shell ipc call plugin:notes-scratchpad toggle";
            "tooltip" = true;
            "tooltip-format" = "Notes";
          };
          "custom/noctalia-todo" = {
            "format" = " ";
            "on-click" = "noctalia-shell ipc call plugin:todo toggle";
            "tooltip" = true;
            "tooltip-format" = "Todo List";
          };
          "custom/noctalia-cheatsheet" = {
            "format" = " ";
            "on-click" = "noctalia-shell ipc call plugin:keybind-cheatsheet toggle";
            "tooltip" = true;
            "tooltip-format" = "Keybindings";
          };
          "custom/noctalia-assistant" = {
            "format" = " ";
            "on-click" = "noctalia-shell ipc call plugin:assistant-panel toggle";
            "tooltip" = true;
            "tooltip-format" = "Assistant";
          };

          "wlr/workspaces" = {
            "format" = "{icon}";
            "on-click" = "activate";
            "on-scroll-up" = "hyprctl dispatch workspace e+1";
            "on-scroll-down" = "hyprctl dispatch workspace e-1";
          };
          "idle_inhibitor" = {
            "format" = "{icon}";
            "format-icons" = {
              "activated" = "";
              "deactivated" = "";
            };
            "tooltip" = false;
          };
          "battery" = {
            "interval" = 10;
            "states" = {
              "warning" = 20;
              "critical" = 10;
            };
            "format" = "{icon} {capacity}%";
            "format-icons" = [
              ""
              ""
              ""
              ""
              ""
              ""
              ""
              ""
              ""
            ];
            "format-full" = "{icon} {capacity}%";
            "format-charging" = " {capacity}%";
            "tooltip" = false;
          };
          "clock" = {
            "on-click" = "wallpaper_random";
            "on-click-right" = "killall dynamic_wallpaper || dynamic_wallpaper &";
            "interval" = 1;
            "format" = "{:%I:%M %p  %A %b %d}";
            "tooltip" = true;
            # "tooltip-format"= "{=%A; %d %B %Y}\n<tt>{calendar}</tt>"
            "tooltip-format" = ''
              上午：高数
              下午：Ps
              晚上：Golang
              <tt>{calendar}</tt>'';
          };
          "memory" = {
            "interval" = 1;
            "format" = "﬙ {percentage}%";
            "states" = {
              "warning" = 85;
            };
          };
          "cpu" = {
            "interval" = 1;
            "format" = " {usage}%";
          };
          "mpd" = {
            "max-length" = 25;
            "format" = "<span foreground='${normal.magenta}'></span> {title}";
            "format-paused" = " {title}";
            "format-stopped" = "<span foreground='${normal.magenta}'></span>";
            "format-disconnected" = "";
            "on-click" = "mpc --quiet toggle";
            "on-click-right" = "mpc ls | mpc add";
            "on-click-middle" = "kitty --class='ncmpcpp' --hold sh -c 'ncmpcpp'";
            "on-scroll-up" = "mpc --quiet prev";
            "on-scroll-down" = "mpc --quiet next";
            "smooth-scrolling-threshold" = 5;
            "tooltip-format" = "{title} - {artist} ({elapsedTime:%M:%S}/{totalTime:%H:%M:%S})";
          };
          "network" = {
            "interval" = 1;
            "format-wifi" = "說 {essid}";
            "format-ethernet" = "  {ifname} ({ipaddr})";
            "format-linked" = "說 {essid} (No IP)";
            "format-disconnected" = "說 Disconnected";
            "tooltip" = false;
          };
          "temperature" = {
            # "hwmon-path"= "${env:HWMON_PATH}";
            #"critical-threshold"= 80;
            "tooltip" = false;
            "format" = " {temperatureC}°C";
          };
          "custom/powermenu" = {
            "format" = "";
            "on-click" = ""; # TODO
            "tooltip" = false;
          };
          "tray" = {
            "icon-size" = 15;
            "spacing" = 5;
          };
        }
      ];
      style = ''
              * {
                font-family: "JetBrainsMono Nerd Font";
                font-size: 12pt;
                font-weight: bold;
                border-radius: 0px;
                transition-property: background-color;
                transition-duration: 0.5s;
              }
              @keyframes blink_red {
                to {
                  background-color: ${normal.red};
                  color: ${types.bg};
                }
              }
              .warning, .critical, .urgent {
                animation-name: blink_red;
                animation-duration: 1s;
                animation-timing-function: linear;
                animation-iteration-count: infinite;
                animation-direction: alternate;
              }
              window#waybar {
                background-color: transparent;
              }
              window > box {
                margin-left: 5px;
                margin-right: 5px;
                margin-top: 5px;
                background-color: ${types.bg};
              }
        #workspaces {
                padding-left: 0px;
                padding-right: 4px;
              }
        #workspaces button {
                padding-top: 5px;
                padding-bottom: 5px;
                padding-left: 6px;
                padding-right: 6px;
              }
        #workspaces button.active {
                background-color: ${normal.cyan};
                color: ${types.bg};
              }
        #workspaces button.urgent {
                color: ${types.bg};
              }
        #workspaces button:hover {
                background-color: ${normal.yellow};
                color: ${types.bg};
              }
              tooltip {
                background: ${types.bg};
              }
              tooltip label {
                color: ${types.fg};
              }
        #custom-launcher {
                font-size: 20px;
                padding-left: 8px;
                padding-right: 6px;
                color: ${normal.cyan};
              }
        #mode, #clock, #memory, #temperature,#cpu,#mpd, #idle_inhibitor, #temperature, #backlight, #pulseaudio, #network, #battery, #custom-powermenu, #custom-cava-internal {
                padding-left: 10px;
                padding-right: 10px;
              }
              /* #mode { */
              /* 	margin-left: 10px; */
              /* 	background-color: rgb(248, 189, 150); */
              /*     color: rgb(26, 24, 38); */
              /* } */
        #memory {
                color: ${normal.cyan};
              }
        #cpu {
                color: ${normal.magenta};
              }
        #clock {
                color: ${types.fg};
              }
        #idle_inhibitor {
                color: ${normal.magenta};
              }
        #temperature {
                color: ${normal.blue};
              }
        #backlight {
                color: ${normal.yellow};
              }
        #pulseaudio {
                color: ${normal.white};
              }
        #network {
                color: ${normal.green};
              }
        #network.disconnected {
                color: ${bright.white};
              }
        #battery.charging, #battery.full, #battery.discharging {
                color: ${normal.yellow};
              }
        #battery.critical:not(.charging) {
                color: ${normal.red};
              }
        #custom-powermenu {
                color: ${normal.red};
              }
        #tray {
                padding-right: 8px;
                padding-left: 10px;
              }
        #mpd.paused {
                color: ${bright.black};
                font-style: italic;
              }
        #mpd.stopped {
                background: transparent;
              }
        #mpd {
                color: ${bright.white};
              }
        #custom-cava-internal{
                font-family: "Hack Nerd Font" ;
              }
      '';
    };
  };
}
