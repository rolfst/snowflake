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
    attrValues
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
      # The package ships Citrix-mime_types.xml in share/applications/
      # but shared-mime-info expects it in share/mime/packages/.
      # Also, ctxwebhelper (receiver:// URL handler) is not exposed in bin/.
      environment.systemPackages = let
        citrix = pkgs.unstable.citrix_workspace;
        citrixMime = pkgs.runCommand "citrix-mime" {} ''
          mkdir -p $out/share/mime/packages
          cp ${citrix}/share/applications/Citrix-mime_types.xml \
             $out/share/mime/packages/
        '';
        citrixWebHelper = pkgs.writeShellScriptBin "ctxwebhelper" ''
          exec ${citrix}/opt/citrix-icaclient/util/ctxwebhelper "$@"
        '';
      in
        (attrValues {
          inherit (pkgs.unstable) citrix_workspace;
        })
        ++ [citrixMime citrixWebHelper];

      # Register handlers for ICA files and Citrix URL schemes
      hm.xdg.mimeApps.defaultApplications = {
        "application/x-ica" = "wfica.desktop";
        "x-scheme-handler/receiver" = "receiver.desktop";
      };
    })
  ];
}
