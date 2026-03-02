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
    };

    services.tailscale = mkIf config.modules.services.streaming.tailscale.enable {
      enable = true;
    };
  };
}
