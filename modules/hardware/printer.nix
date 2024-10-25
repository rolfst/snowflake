{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
in {
  options.modules.hardware.printer = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "printer support";};

  config = mkIf config.modules.hardware.printer.enable {
    services.printing = {
      enable = true;
      drivers = [pkgs.hplipWithPlugin pkgs.xsane];
      browsing = true;
      defaultShared = true;
      allowFrom = ["all"];
      openFirewall = true;
      listenAddresses = [
        "*:631"
      ];
    };
    services.printing.browsedConf = ''
      BrowseDNSSDSubTypes _cups,_print
      BrowseLocalProtocols all
      BrowseRemoteProtocols all
      CreateIPPPrinterQueues All

      BrowseProtocols all
    '';
    user.packages = [pkgs.xsane pkgs.gtklp];

    hardware.sane = {
      enable = true;
      extraBackends = [pkgs.hplipWithPlugin];
    };
    services.ipp-usb.enable = true;

    # Enable wireless access to printers
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      # nssmdns = true;
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };
}
