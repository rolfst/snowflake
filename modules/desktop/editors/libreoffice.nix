{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib) mkDictFromLibreofficeGit;
in {
  options.modules.desktop.editors.libreoffice = let
    inherit (lib.options) mkEnableOption;
  in {enable = mkEnableOption "post-modern office suit";};

  # let
  #   nl-nl = mkDictFromLibreofficeGit {
  #     subdir = "nl";
  #     shortName = "nl-nl";
  #     shortDescription = "Nederlands (Nederland)";
  #     dictFileName = "nl_NL";
  #     readmeFileName = "nl";
  #   };
  # in {
  config = mkIf config.modules.desktop.editors.libreoffice.enable {
    # nl_NL = nl-nl;
    # nl-nl = mkDictFromLibreofficeGit {
    #   subdir = "nl";
    #   shortName = "nl-nl";
    #   shortDescription = "Nederlands (Nederland)";
    #   dictFileName = "nl_NL";
    #   readmeFileName = "nl";
    # };
    user.packages = attrValues {
      inherit (pkgs) libreoffice hunspell; # hyphenDicts.nl_NL;
      inherit (pkgs.hunspellDicts) en_US; #nl_NL
    };
  };
  # };
}
