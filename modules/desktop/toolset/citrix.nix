{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkMerge
    ;

  cfg = config.modules.desktop.toolset.citrix;
in
{
  options.modules.desktop.toolset.citrix = {
    enable = mkEnableOption "remote desktop for enterprises";
  };
  config = mkMerge [
    (mkIf cfg.enable {
      # ctxwebhelper (receiver:// URL handler) is not exposed in bin/.
      environment.systemPackages = let
        citrix = pkgs.unstable.citrix-workspace;
        citrixWebHelper = pkgs.writeShellScriptBin "ctxwebhelper" ''
          exec ${citrix}/opt/citrix-icaclient/util/ctxwebhelper "$@"
        '';
      in
        [citrix citrixWebHelper];

      # Register handlers for ICA files and Citrix URL schemes
      hm.xdg.mimeApps.defaultApplications = {
        "application/x-ica" = "wfica.desktop";
        "x-scheme-handler/receiver" = "receiver.desktop";
      };
    })
  ];
}
