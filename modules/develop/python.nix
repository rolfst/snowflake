{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
  cfg = config.modules.develop.python;
in {
  options.modules.develop.python = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "Python development";};

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = attrValues {
        pyWithEnv = pkgs.python3.withPackages (ps:
          with ps; [
            black
            isort
            ipython
          ]);
        inherit (pkgs) pyright rye pdm;
        inherit (pkgs.unstable.python3Packages) pynvim;
      };

      environment.shellAliases = {
        py = "python";
        pip = "rye";
        ipy = "ipython --no-banner";
        ipylab = "ipython --pylab=qt5 --no-banner";
      };

      hm.programs.vscode.extensions = attrValues {
        inherit (pkgs.vscode-extensions.ms-python) python;
        inherit (pkgs.vscode-extensions.ms-toolsai) jupyter;
      };
    }

    (mkIf config.modules.develop.xdg.enable {
      home.sessionVariables = {
        PYTHON_HISTORY_FILE = "$XDG_DATA_HOME/python/history";
        IPYTHONDIR = "$XDG_CONFIG_HOME/ipython";
        JUPYTER_CONFIG_DIR = "$XDG_CONFIG_HOME/jupyter";
      };
    })
  ]);
}
