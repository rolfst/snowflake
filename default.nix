{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) toString;
  inherit
    (lib)
    attrValues
    filterAttrs
    mkDefault
    mkIf
    mkAliasOptionModule
    mapAttrs
    mapAttrsToList
    ;
  inherit (lib.my) mapModulesRec';
in {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-flatpak.nixosModules.nix-flatpak
      (mkAliasOptionModule ["hm"] ["home-manager" "users" config.user.name])
      (mkAliasOptionModule ["home"] ["hm" "home"])
      (mkAliasOptionModule ["create" "configFile"] ["hm" "xdg" "configFile"])
      (mkAliasOptionModule ["create" "dataFile"] ["hm" "xdg" "dataFile"])
      (mkAliasOptionModule ["create" "homeFile"] ["hm" "home" "file"])
    ]
    ++ (mapModulesRec' (toString ./modules) import);

  # Common config for all nixos machines;
  environment.variables = {
    SNOWFLAKE = config.snowflake.dir;
    SNOWFLAKE_BIN = config.snowflake.binDir;
    NIXPKGS_ALLOW_UNFREE = "1";
    NIXPKGS_ALLOW_INSECURE = "1";
  };

  nix = let
    filteredInputs = filterAttrs (n: _: n != "self") inputs;
    nixPathInputs = mapAttrsToList (n: v: "${n}=${v}") filteredInputs;
    registryInputs = mapAttrs (_: v: {flake = v;}) filteredInputs;
  in {
    # package = pkgs.nixVersions.git;
    extraOptions = "experimental-features = nix-command flakes";

    nixPath =
      nixPathInputs
      ++ [
        "nixpkgs-overlays=${config.snowflake.dir}/overlays"
        "snowflake=${config.snowflake.dir}"
      ];

    registry = registryInputs // {snowflake.flake = inputs.self;};

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than-2d";
    };

    settings = {
      auto-optimise-store = true;
      keep-derivations = false;
      keep-outputs = false;

      substituters = ["https://nix-community.cachix.org" "https://hyprland.cachix.org"];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };

  system = {
    stateVersion = "25.05";
    configurationRevision = with inputs; mkIf (self ? rev) self.rev;
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };

  # Some reasonable, global defaults
  ## This is here to appease 'nix flake check' for generic hosts with no
  ## hardware-configuration.nix or fileSystem config.
  hardware.block.scheduler = {
    "mmcblk[0-9]*" = "bfq";
    "nvme[0-9]*" = "kyber";
  };

  fileSystems."/".device = mkDefault "/dev/disk/by-uuid/238f6eb4-b155-499e-b75a-2f1d233797ed";

  boot = {
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
    kernelParams = ["pcie_aspm.policy=performance"];
    loader = {
      systemd-boot.enable = true;
      efi.efiSysMountPoint = "/boot";
      efi.canTouchEfiVariables = mkDefault true;
    };
  };

  console = {
    font = mkDefault "Lat2-Terminus16";
    useXkbConfig = mkDefault true;
  };

  time.timeZone = "Europe/Amsterdam";
  services.geoclue2.enable = true;
  # services.automatic-timezoned.enable = true;
  # services.localtimed.enable = true;

  i18n = {
    defaultLocale = mkDefault "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "nl_NL.UTF-8";
      LC_IDENTIFICATION = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_NAME = "nl_NL.UTF-8";
      LC_NUMERIC = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
      LC_TELEPHONE = "nl_NL.UTF-8";
      LC_TIME = "nl_NL.UTF-8";
    };
  };

  # WARNING: prevent installing pre-defined packages
  environment.defaultPackages = [];

  environment.systemPackages =
    attrValues {inherit (pkgs) cached-nix-shell gnumake unrar xz unzip corefonts udisks udiskie usbutils e2fsprogs dosfstools;};
}
