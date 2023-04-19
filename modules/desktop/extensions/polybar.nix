{
  inputs,
  options,
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.my) mkBoolOpt;

  cfg = config.modules.desktop.extensions.polybar;

  openCalendar = "${pkgs.xfce.orage}/bin/orage";

  hdmiBar = pkgs.callPackage ../../../config/polybar/bar.nix {};

  laptopBar = pkgs.callPackage ../../../config/polybar/bar.nix {
    font0 = 10;
    font1 = 12;
    font2 = 24;
    font3 = 18;
    font4 = 5;
    font5 = 10;
  };

  mainBar =
    if specialArgs.hidpi
    then hdmiBar
    else laptopBar;

  mypolybar = pkgs.polybar.override {
    alsaSupport = true;
    githubSupport = true;
    mpdSupport = true;
    pulseSupport = true;
  };

  # theme adapted from: https://github.com/adi1090x/polybar-themes#-polybar-5
  # bars = builtins.readFile ./config.ini;

  bluetoothScript = pkgs.callPackage ../../../config/polybar/scripts/bluetooth.nix {};
  klsScript = pkgs.callPackage ../../../config/polybar/scripts/keyboard-layout-switch.nix {inherit pkgs;};
  monitorScript = pkgs.callPackage ../../../scripts/monitor.nix {};
  mprisScript = pkgs.callPackage ../../../scripts/mpris.nix {};
  networkScript = pkgs.callPackage ../../../scripts/network.nix {};

  bctl = ''
    [module/bctl]
    type = custom/script
    exec = ${bluetoothScript}/bin/bluetooth-ctl
    tail = true
    click-left = ${bluetoothScript}/bin/bluetooth-ctl --toggle &
  '';

  cal = ''
    [module/clickable-date]
    inherit = module/date
    label = %{A1:${openCalendar}:}%time%%{A}
  '';

  keyboard = ''
    [module/clickable-keyboard]
    inherit = module/keyboard
    label-layout = %{A1:${klsScript}/bin/kls:}  %layout% %icon% %{A}
  '';

  mpris = ''
    [module/mpris]
    type = custom/script

    exec = ${mprisScript}/bin/mpris
    tail = true

    label-maxlen = 60

    interval = 2
    format =   <label>
    format-padding = 2
  '';

  xmonad = ''
    [module/xmonad]
    type = custom/script
    exec = ${pkgs.xmonad-log}/bin/xmonad-log

    tail = true
  '';

  customMods = mainBar + bctl + cal + keyboard + mpris + xmonad;
in {
  options.modules.desktop.extensions.polybar = {enable = mkBoolOpt false;};
  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        font-awesome # awesome fonts
        material-design-icons # fonts with glyphs
        xfce.orage # lightweight calendar
      ];
      services = {
        status-notifier-watcher.enable = true;

        polybar = {
          enable = true;
          package = mypolybar;
          config = ../../../polybar/config.ini;
          extraConfig = customMods;
          # polybar top -l trace (or info) for debugging purposes
          script = ''
            export MONITOR=$(${monitorScript}/bin/monitor)
            echo "Running polybar on $MONITOR"
            export ETH_INTERFACE=$(${networkScript}/bin/check-network eth)
            export WIFI_INTERFACE=$(${networkScript}/bin/check-network wifi)
            echo "Network interfaces $ETH_INTERFACE & $WIFI_INTERFACE"
            polybar top 2>${config.xdg.configHome}/polybar/logs/top.log & disown
            polybar bottom 2>${config.xdg.configHome}/polybar/logs/bottom.log & disown
          '';
        };
      };
    };
  };
}
