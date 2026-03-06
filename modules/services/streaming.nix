{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  wlr-randr = "${pkgs.wlr-randr}/bin/wlr-randr";
  grep = "${pkgs.gnugrep}/bin/grep";

  # Monitor identifiers — adjust if hardware changes
  laptopOutput = "eDP-1";
  externalOutput = "HDMI-A-2";
  externalMode = "1920x1080@60Hz";

  # Switch to external monitor if connected, otherwise keep laptop screen
  switchToExternal = pkgs.writeShellScript "sunshine-switch-external" ''
    if ${wlr-randr} | ${grep} -q '${externalOutput}'; then
      ${wlr-randr} --output ${externalOutput} --on --mode ${externalMode}
      ${wlr-randr} --output ${laptopOutput} --off
    fi
  '';

  # Restore laptop monitor; turn off external if it exists
  restoreLaptop = pkgs.writeShellScript "sunshine-restore-laptop" ''
    ${wlr-randr} --output ${laptopOutput} --on
    if ${wlr-randr} | ${grep} -q '${externalOutput}'; then
      ${wlr-randr} --output ${externalOutput} --off
    fi
  '';

  # Switch to laptop monitor, turn off external if it exists
  switchToLaptop = pkgs.writeShellScript "sunshine-switch-laptop" ''
    ${wlr-randr} --output ${laptopOutput} --on
    if ${wlr-randr} | ${grep} -q '${externalOutput}'; then
      ${wlr-randr} --output ${externalOutput} --off
    fi
  '';

  # Restore external monitor; keep laptop on as fallback
  restoreExternal = pkgs.writeShellScript "sunshine-restore-external" ''
    if ${wlr-randr} | ${grep} -q '${externalOutput}'; then
      ${wlr-randr} --output ${externalOutput} --on --mode ${externalMode}
    fi
    ${wlr-randr} --output ${laptopOutput} --on
  '';

  # Prep-cmd for apps that should stream from the external monitor
  externalMonitorPrepCmd = [
    {
      do = "${switchToExternal}";
      undo = "${restoreLaptop}";
    }
  ];

  # Prep-cmd for apps that should stream from the laptop screen
  laptopMonitorPrepCmd = [
    {
      do = "${switchToLaptop}";
      undo = "${restoreExternal}";
    }
  ];
in
{
  options.modules.services.streaming = {
    enable = mkEnableOption "desktop streaming services";
    sunshine.enable = mkEnableOption "Sunshine streaming server";
    tailscale.enable = mkEnableOption "Tailscale client";
  };

  config = mkIf config.modules.services.streaming.enable {
    services.sunshine = mkIf config.modules.services.streaming.sunshine.enable {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
      settings = {
        capture = "kms";
        adapter_name = "/dev/dri/renderD128";
        output_name = "0";
      };
      applications = {
        apps = [
          # ── Laptop variants ──
          {
            name = "Desktop (Laptop)";
            prep-cmd = laptopMonitorPrepCmd;
          }
          {
            name = "kitty Terminal (Laptop)";
            auto-detach = true;
            detached = [ "kitty" ];
            working-dir = "/home/rolfst";
            prep-cmd = laptopMonitorPrepCmd;
          }
          {
            name = "Steam (Laptop)";
            detached = [ "setsid steam steam://open/bigpicture" ];
            prep-cmd = laptopMonitorPrepCmd;
          }
          # ── External monitor variants ──
          {
            name = "Desktop (External)";
            prep-cmd = externalMonitorPrepCmd;
          }
          {
            name = "kitty Terminal (External)";
            auto-detach = true;
            detached = [ "kitty" ];
            working-dir = "/home/rolfst";
            prep-cmd = externalMonitorPrepCmd;
          }
          {
            name = "Steam (External)";
            detached = [ "setsid steam steam://open/bigpicture" ];
            prep-cmd = externalMonitorPrepCmd;
          }
        ];
      };
    };

    services.tailscale = mkIf config.modules.services.streaming.tailscale.enable {
      enable = true;
      # This flag tells Tailscale to tell the network "I can be an exit node"
      extraUpFlags = [ "--advertise-exit-node" ];
    };
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 47984 47989 48010 ];
      allowedUDPPorts = [ 47998 47999 48000 48002 48010 ];
      checkReversePath = "loose";
    };
    user.extraGroups = [
      "input"
      "video"
      "render"
    ];

    services.udev = {
      extraRules = ''
        KERNEL=="uinput",MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
      '';
    };
  };
}
