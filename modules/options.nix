{
  config,
  options,
  lib,
  home-manager,
  ...
}: let
  inherit (builtins) elem pathExists toString;
  inherit
    (lib)
    findFirst
    isList
    mapAttrs
    mapAttrsToList
    mkAliasDefinitions
    mkOption
    ;
  inherit (lib.strings) concatMapStringsSep concatStringsSep;
  inherit (lib.types) attrs attrsOf either listOf oneOf path str;
  inherit (lib.my) mkOpt mkOpt';
in {
  options = {
    user = mkOpt attrs {};

    snowflake = {
      dir = mkOpt path (findFirst pathExists (toString ../.) [
        "${config.user.home}/snowflake"
        "/etc/snowflake"
        "/etc/nixos/snowflake"
      ]);
      hostDir =
        mkOpt path
        "${config.snowflake.dir}/hosts/${config.networking.hostName}";
      binDir = mkOpt path "${config.snowflake.dir}/bin";
      configDir = mkOpt path "${config.snowflake.dir}/config";
      modulesDir = mkOpt path "${config.snowflake.dir}/modules";
      themesDir = mkOpt path "${config.snowflake.modulesDir}/themes";
    };
  };

  config = {
    user = let
      user = builtins.getEnv "USER";
      name =
        if elem user ["" "root"]
        then "rolfst"
        else user;
    in {
      inherit name;
      description = "Primary user account";
      extraGroups = ["wheel" "dialout" "input" "audio" "video" "storage" "scanner" "lp" "disk"];
      isNormalUser = true;
      home = "/home/${name}";
      group = "users";
      uid = 1000;
    };

    # Necessary for nixos-rebuild build-vm to work.
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";
    home-manager.useGlobalPkgs = true;

    home = {
      stateVersion = config.system.stateVersion;
      sessionPath = ["$SNOWFLAKE_BIN" "$XDG_BIN_HOME" "$PATH"];
    };

    # hm.xdg = {
    #   configFile = mkAliasDefinitions options.home.configFile;
    #   dataFile = mkAliasDefinitions options.home.dataFile;
    # };

    users.users.${config.user.name} = mkAliasDefinitions options.user;

    nix.settings = let
      users = ["root" config.user.name];
    in {
      trusted-users = users;
      allowed-users = users;
    };

    # environment.extraInit =
    #   concatStringsSep "\n"
    #   (mapAttrsToList (n: v: ''export ${n}="${v}"'') config.env);
  };
}
