{ options, config, lib, pkgs, ... }:

let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str path nullOr either;

  cfg = config.modules.networking.openvpn;
in {
  options.modules.networking.openvpn = {
    enable = mkEnableOption "OpenVPN client";

    configFile = mkOption {
      type = nullOr (either path str);
      default = null;
      description = "Path to the OpenVPN client configuration file (.ovpn). Accepts a Nix path (read at eval time) or a string path (referenced at runtime, e.g. from age.secrets).";
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
      config =
        if builtins.isPath cfg.configFile
        then builtins.readFile cfg.configFile
        else "config ${cfg.configFile}";
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
