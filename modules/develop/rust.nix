{
  inputs,
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.meta) getExe;
in
{
  options.modules.develop.rust =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "Rust development";
    };

  config = mkMerge [
    (mkIf config.modules.develop.rust.enable (
      let
        codelldb = pkgs.unstable.vscode-extensions.vadimcn.vscode-lldb;
      in
      {
        nixpkgs.overlays = [ inputs.rust.overlays.default ];

        user.packages = attrValues {
          # rust-package = pkgs.rust-bin.stable.latest.default;
          rust-package = pkgs.rust-bin.selectLatestNightlyWith (
            toolchain:
            toolchain.default.override {
              extensions = [
                "rust-analyzer"
                "rust-src"
              ];
            }
          );
          inherit (pkgs.unstable) rustup rust-analyzer rust-script;
          inherit codelldb;
        };

        home.sessionVariables.CODELLDB_PATH = "${codelldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";

        environment.shellAliases = {
          rs = "rustc";
          ca = "cargo";
        };

        hm.programs.vscode.profiles.default.extensions = attrValues {
          inherit (pkgs.vscode-extensions.rust-lang) rust-analyzer;
        };
      }
    ))

    (mkIf config.modules.develop.xdg.enable {
      home = {
        sessionVariables.CARGO_HOME = "$XDG_DATA_HOME/cargo";
        sessionPath = [ "$CARGO_HOME/bin" ];
      };
    })
  ];
}
