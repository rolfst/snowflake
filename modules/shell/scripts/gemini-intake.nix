{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
in
{
  options.modules.shell.scripts.gemini-intake = {
    enable = mkEnableOption "gemini chat export intake tool";
  };

  config = mkIf config.modules.shell.scripts.gemini-intake.enable {
    user.packages = [ pkgs.my.gemini-intake ];

    hm.systemd.user.services.gemini-intake = {
      Unit = {
        Description = "Gemini chat export intake";
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.my.gemini-intake}/bin/gemini-intake";
      };
    };

    hm.systemd.user.timers.gemini-intake = {
      Unit = {
        Description = "Run Gemini intake nightly";
      };
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
