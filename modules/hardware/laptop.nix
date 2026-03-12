{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.attrsets) attrValues;
  cfg = config.modules.hardware.laptop;
in
{
  options.modules.hardware.laptop =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "laptop support";
    };

  config = mkMerge [
    (mkIf cfg.enable {
      # Disable protectKernelImage on laptops: it adds "nohibernate" to kernel
      # params, which prevents suspend-then-hibernate from working.
      security.protectKernelImage = lib.mkForce false;

      services.logind = {
        settings.Login = {
          HandleLidSwitch = "suspend-then-hibernate";
          HandleLidSwitchExternalPower = "suspend-then-hibernate";
          HandleLidSwitchDocked = "suspend-then-hibernate";
        };
      };
      systemd.sleep.extraConfig = ''
        HibernateDelaySec=15min
      '';
      services.auto-cpufreq.enable = true;
      services.auto-cpufreq.settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    })
  ];
}
