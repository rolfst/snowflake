{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.modules) mkIf mkMerge;
in {
  options.modules.develop.java = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "Java development";};

  config = mkMerge [
    (mkIf config.modules.develop.clojure.enable {
      user.packages = attrValues {inherit (pkgs) jdk20 jdt-language-server netbeans;};
    })
  ];
}
