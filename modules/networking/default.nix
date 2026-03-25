{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkDefault;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.modules.networking;
in
{
  options.modules.networking =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      iwd.enable = mkEnableOption "wpa_supplicant alt.";
      networkd.enable = mkEnableOption "systemd network manager";
      networkManager.enable = mkEnableOption "powerful network manager";
    };

  config = mkMerge [
    (mkIf cfg.iwd.enable {
      networking = {
        networkmanager = {
        };

        wireless.extraConfig = "country=NL";
        # wireless.iwd = {
        #   enable = false;
        #   settings = {
        #     General = {
        #       AddressRandomization = "network";
        #       AddressRandomizationRange = "full";
        #       EnableNetworkConfiguration = true;
        #       RoamRetryInterval = 15;
        #     };
        #     Network = {
        #       EnableIPv6 = true;
        #       RoutePriorityOffset = 300;
        #       # NameResolvingService = "resolvconf";
        #     };
        #     Settings = {
        #       AutoConnect = true;
        #       # AlwaysRandomizeAddress = false;
        #     };
        #     Rank.BandModifier5Ghz = 2.0;
        #     Scan.DisablePeriodicScan = true;
        #   };
        # };
      };

      # A GUI for easier network management:
      user.packages = [
        pkgs.iwgtk
        pkgs.iw
      ];

      # Launch indicator as a daemon on login:
      systemd.user.services.iwgtk = {
        serviceConfig.ExecStart = "${getExe pkgs.iwgtk} -i";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
      };
    })

    (mkIf cfg.networkManager.enable {
      systemd.services.NetworkManager-wait-online.enable = false;

      user.packages = [ pkgs.iw ];
      networking.networkmanager = {
        enable = mkDefault true;
        wifi.backend = "wpa_supplicant";
        settings = {
          connection = {
            "wifi.powersave" = 2;
          };
          # main = {
          #   auth-polkit = true; # Ensures Gui prompts work properly
          # };
        };
      };

      # Display a network-manager applet:
      hm.services.network-manager-applet.enable = true;
    })

    # TODO: add network connections + ragenix.
    (mkIf cfg.networkd.enable {
      systemd.network.enable = true;

      systemd.services = {
        systemd-networkd-wait-online.enable = false;
        systemd-networkd.restartIfChanged = false;
        firewall.restartIfChanged = false;
      };

      networking.interfaces = {
        enp1s0.useDHCP = true;
        wlan0.useDHCP = true;
      };
    })
  ];
}
