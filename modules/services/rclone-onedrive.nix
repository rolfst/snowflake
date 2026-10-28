{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) listOf str;

  cfg = config.modules.services.rclone-onedrive;
  rcloneConf = "${config.user.home}/.config/rclone/rclone.conf";

  syncScript = pkgs.writeShellScript "rclone-onedrive-sync" ''
    set -u
    rc=0
    for name in ${lib.escapeShellArgs cfg.directories}; do
      src="${cfg.localRoot}/$name"
      dst="${cfg.remote}:${cfg.remotePath}/$name"
      [ -d "$src" ] || { echo "skip $src (missing)"; continue; }
      ${pkgs.rclone}/bin/rclone bisync "$src" "$dst" \
        --create-empty-src-dirs --resilient --recover \
        ${lib.concatMapStringsSep " " (e: "--exclude ${lib.escapeShellArg e}") cfg.excludes} \
        || rc=1
    done
    exit $rc
  '';
in
{
  options.modules.services.rclone-onedrive = {
    enable = mkEnableOption "rclone bisync with DHL OneDrive/SharePoint";

    remote = mkOption {
      type = str;
      default = "dhl";
      description = "rclone remote name (create it once with `rclone config`, type onedrive).";
    };

    remotePath = mkOption {
      type = str;
      default = "Rolf Strijdhorst";
      description = "Folder (shortcut) in the remote that receives the directories.";
    };

    localRoot = mkOption {
      type = str;
      default = "${config.user.home}/workspaces/DHL-doc/personal";
      description = "Local directory containing the folders to sync.";
    };

    directories = mkOption {
      type = listOf str;
      default = [
        "People"
        "agents"
        "handbook"
        "templates"
      ];
      description = "Sub-directories of localRoot that are bisynced.";
    };

    excludes = mkOption {
      type = listOf str;
      default = [
        ".git/**"
        ".jj/**"
        ".omo/**"
        ".codegraph/**"
      ];
      description = "rclone exclude patterns.";
    };

    interval = mkOption {
      type = str;
      default = "15min";
      description = "Time between syncs (OnUnitActiveSec).";
    };
  };

  config = mkIf cfg.enable {
    user.packages = [ pkgs.rclone ];

    # The remote token is created interactively (`rclone config`) and refreshed
    # by rclone itself, so the config lives outside Nix. Services stay inert on
    # hosts where it, or the local folder, does not exist yet.
    hm.systemd.user.services.rclone-onedrive = {
      Unit = {
        Description = "rclone bisync DHL-doc folders with OneDrive";
        After = [ "network-online.target" ];
        ConditionPathExists = [
          rcloneConf
          cfg.localRoot
        ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${syncScript}";
      };
    };

    hm.systemd.user.timers.rclone-onedrive = {
      Unit.Description = "Timer for rclone OneDrive bisync";
      Timer = {
        OnBootSec = "5min";
        OnUnitActiveSec = cfg.interval;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
