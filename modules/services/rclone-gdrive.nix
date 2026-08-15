{
  options,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) listOf str;

  cfg = config.modules.services.rclone-gdrive;
in
{
  options.modules.services.rclone-gdrive = {
    enable = mkEnableOption "rclone Google Drive sync";

    remote = mkOption {
      type = str;
      default = "gdrive";
      description = "Name of the rclone remote as defined in the config file.";
    };

    directories = mkOption {
      type = listOf str;
      default = [ ];
      description = ''
        List of absolute local directory paths to copy to Google Drive.
        Each directory is copied to a matching path under the remote root.
      '';
      example = [ "/home/rolfst/Documents" ];
    };

    excludes = mkOption {
      type = listOf str;
      default = [
        ".git/**"
        ".jj/**"
      ];
      description = "rclone exclude patterns applied to every sync job.";
    };

    interval = mkOption {
      type = str;
      default = "15min";
      description = "systemd timer interval between syncs (OnUnitActiveSec).";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.directories != [ ];
        message = "modules.services.rclone-gdrive.directories must not be empty when enabled.";
      }
    ];

    age.secrets."rclone-gdrive" = {
      file = "${inputs.self}/secrets/rclone-gdrive.age";
      owner = config.user.name;
      group = config.user.group;
      mode = "0400";
    };

    user.packages = [ pkgs.rclone ];

    # One systemd service + timer per directory
    systemd.services = builtins.listToAttrs (
      map (dir: {
        name = "rclone-gdrive-${builtins.baseNameOf dir}";
        value = {
          description = "rclone copy ${dir} to Google Drive";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = config.user.name;
            ExecStart =
              let
                excludeArgs = lib.concatMapStringsSep " " (e: "--exclude '${e}'") cfg.excludes;
                remotePath = "${cfg.remote}:${dir}";
              in
              "${pkgs.rclone}/bin/rclone copy ${dir} ${remotePath} ${excludeArgs} --config %d/rclone.conf";
            LoadCredential = "rclone.conf:${config.age.secrets."rclone-gdrive".path}";
          };
        };
      }) cfg.directories
    );

    systemd.timers = builtins.listToAttrs (
      map (dir: {
        name = "rclone-gdrive-${builtins.baseNameOf dir}";
        value = {
          description = "Timer for rclone copy of ${dir} to Google Drive";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5min";
            OnUnitActiveSec = cfg.interval;
            Unit = "rclone-gdrive-${builtins.baseNameOf dir}.service";
          };
        };
      }) cfg.directories
    );
  };
}
