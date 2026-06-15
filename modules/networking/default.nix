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
      networkManager = {
        enable = mkEnableOption "powerful network manager";
        useIwd = mkEnableOption "use iwd as the wifi backend instead of wpa_supplicant";
      };
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
        wifi.backend = if cfg.networkManager.useIwd then "iwd" else "wpa_supplicant";
        # Use systemd-resolved for split DNS: VPN domains route to VPN DNS,
        # Tailscale domains route to Tailscale DNS, no conflicts.
        dns = "systemd-resolved";
        settings = {
          connection = {
            "wifi.powersave" = 2;
          };
        };
      };

      # systemd-resolved provides per-link DNS routing so Tailscale and
      # the DHL Azure VPN coexist without overwriting each other's DNS.
      services.resolved = {
        enable = true;
        # Fallback DNS when no link-specific server matches.
        fallbackDns = [
          "1.1.1.1"
          "9.9.9.9"
        ];
        # DNSSEC causes issues with split-horizon internal zones.
        dnssec = "false";
      };

      # Display a network-manager applet:
      hm.services.network-manager-applet.enable = true;
    })

    (mkIf (cfg.networkManager.enable && cfg.networkManager.useIwd) {
      # iwd behaves as NetworkManager's WiFi backend; configure it for stability.
      #
      # DisablePeriodicScan: prevents iwd from scanning in the background while
      # connected.  Without this, iwd finds the second mesh BSS and repeatedly
      # attempts 802.11r Fast Transition to it, always timing out → periodic
      # deauths.
      #
      # RoamRetryInterval: when a roam attempt fails, wait 60 s before retrying
      # (default is much shorter), reducing the spray of FT failures in the log.
      networking.wireless.iwd.settings = {
        General = {
          AddressRandomization = "network";
          RoamRetryInterval = 60;
          Country = "NL"; # regulatory domain (kernel defaults to "country 00: DFS-UNSET")
        };
        Scan.DisablePeriodicScan = true;
        Rank.BandModifier5Ghz = 1.5; # slight 5 GHz preference over 2.4 GHz
      };

      # On resume from sleep/hibernate iwd's initial scan fires before the
      # kernel interface is ready → "Network is down" → falls into slow
      # autoconnect_full (≈20 s).  Restarting iwd 2 s after resume lets it
      # start with a clean state and reconnects in <5 s.
      systemd.services."iwd-resume" = {
        description = "Restart iwd after resume from suspend";
        after = [ "post-resume.target" ];
        wantedBy = [ "post-resume.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
          ExecStart = "${pkgs.systemd}/bin/systemctl restart iwd";
        };
      };
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
