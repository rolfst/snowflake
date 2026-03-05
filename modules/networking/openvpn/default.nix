{ options, config, lib, pkgs, ... }:

let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str path nullOr;

  cfg = config.modules.networking.openvpn;
in {
  options.modules.networking.openvpn = {
    enable = mkEnableOption "OpenVPN client";

    configFile = mkOption {
      type = nullOr path;
      default = null;
      description = "Path to the OpenVPN client configuration file (.ovpn).";
    };

    name = mkOption {
      type = str;
      default = "company";
      description = "Name for the OpenVPN connection (used in systemd service name).";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.configFile != null;
        message = "modules.networking.openvpn.configFile must be set to the path of your .ovpn config file.";
      }
    ];

    services.openvpn.servers.${cfg.name} = {
      config = builtins.readFile cfg.configFile;
      autoStart = false;
    };

    # Ensure the tun device is available:
    boot.kernelModules = [ "tun" ];

    networking.firewall = {
      allowedUDPPorts = [ 1194 ];
      allowedTCPPorts = [ 443 ];
    };

    environment.systemPackages = [
      pkgs.openvpn
      pkgs.networkmanager-openvpn
      pkgs.networkmanagerapplet # nm-connection-editor + nm-applet
    ];

    # NetworkManager plugin for GUI management via the network applet:
    networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

    # Don't start on boot -- connect manually:
    #   sudo systemctl start openvpn-<name>.service
    # Disconnect:
    #   sudo systemctl stop openvpn-<name>.service
    # Status:
    #   systemctl status openvpn-<name>.service
  };
}
