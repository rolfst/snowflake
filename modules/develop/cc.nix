{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.modules.develop.cc = {
    enable = mkEnableOption "C/C++ development environment";
  };

  config = mkIf config.modules.develop.cc.enable (mkMerge [
    {
      user.packages = with pkgs; [
        gcc
        gnumake
        clang-tools
        xmake
      ];
    }

    (mkIf config.modules.develop.xdg.enable {
      create.configFile."clangd/config.yaml" = {
        text = generators.toYAML {} {
          CompileFlags = {
            Add = [
              "-xc"
              "-Wall"
              "-Wextra"
              "-Werror"
            ];
          };
        };
      };
      create.homeFile.".clang-format" = {
        text = ''
          ---
          BasedOnStyle: LLVM
          IndentWidth: 8
          UseTab: Always
          BreakBeforeBraces: Linux
          AllowShortIfStatementsOnASingleLine: false
          IndentCaseLabels: false
          ...
        '';
      };
    })
  ]);
}
