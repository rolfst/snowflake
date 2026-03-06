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
      applications = {
        apps = [
          {
            name = "kitty Terminal";
            auto-detach = true;
            detached = [ "kitty" ];
            working-dir = "/home/rolfst";
          }
          {
            name = "Steam";
            detached = [ "setsid steam steam://open/bigpicture" ];
            # cmd = "${pkgs.steam}/bin/steam steam://open/bigpicture";
          }
          {
            name = "Desktop";
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
