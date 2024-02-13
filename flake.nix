{
  description = "λ simple and configureable Nix-Flake repository!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    home-manager = {
      # url = "github:nix-community/home-manager/master";
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System application(s)
    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Window Manager(s) + Extensions
    xmonad-contrib.url = "github:icy-thought/xmonad-contrib";
    hyprland.url = "github:hyprwm/Hyprland";

    # Toolset ++ Application(s)
    rust.url = "github:oxalica/rust-overlay";

    nvim-dir = {
      url = "https://github.com/rolfst/nvim.git?rev=04d3cc4f66114fa24f1642ed5a30d41e9c8f3b8c";
      type = "git";
      submodules = true;
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    ...
  }: let
    inherit (lib.my) mapModules mapModulesRec mapHosts;
    system = "x86_64-linux";

    mkPkgs = pkgs: extraOverlays:
      import pkgs {
        inherit system;
        config.nvidia.acceptLicense = true;
        config.allowUnfree = true;

        config.permittedInsecurePackages = [
          "electron-25.9.0"
        ];
        overlays = extraOverlays ++ (lib.attrValues self.overlays);
      };
    pkgs = mkPkgs nixpkgs [self.overlays.default];
    pkgs' = mkPkgs nixpkgs-unstable [];

    lib = nixpkgs.lib.extend (final: prev: {
      my = import ./lib {
        inherit pkgs inputs;
        lib = final;
      };
    });
  in rec {
    lib = lib.my;

    overlays =
      (mapModules ./overlays import)
      // {
        default = final: prev: {
          unstable = pkgs';
          my = self.packages.${system};
        };
      };

    packages."${system}" = mapModules ./packages (p: pkgs.callPackage p {});

    nixosModules =
      {
        snowflake = import ./.;
      }
      // mapModulesRec ./modules import;

    nixosConfigurations = mapHosts ./hosts {};
    homeConfigurations = {
      cleo = nixosConfigurations.cleo.config.home-manager.users.${nixosConfigurations.cleo.config.user.name}.home;
    };

    devShells."${system}".default = import ./shell.nix {
      inherit pkgs;
      inherit lib;
    };

    templates.full =
      {
        path = ./.;
        description = "λ well-tailored and configureable NixOS system!";
      }
      // import ./templates;

    templates.default = self.templates.full;

    # TODO: deployment + template tool.
    # apps."${system}" = {
    #   type = "app";
    #   program = ./bin/hagel;
    # };
  };
}
