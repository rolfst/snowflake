{
  description = "λ simple and configureable Nix-Flake repository!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
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
    xmonad-contrib.url = "github:icy-thought/xmonad-contrib"; # TODO: replace with official after #582 == merged!
    hyprland.url = "github:hyprwm/Hyprland";

    # Toolset ++ Application(s)
    nvim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.url = "github:nixos/nixpkgs";
    };
    rust.url = "github:oxalica/rust-overlay";

    nvim-dir = {
      url = "https://github.com/rolfst/nvim.git?rev=6f0c231f7a8fd271e3b2e3499e643feecfca9f51";
      type = "git";
      submodules = true;
      flake = false;
    };
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, ... }:
  let
    inherit (lib.my) mapModules mapModulesRec mapHosts;
    system = "x86_64-linux";

    mkPkgs = pkgs: extraOverlays:
      import pkgs {
        inherit system;
        config.allowUnfree = true;
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
  in {
    lib = lib.my;

    overlays = (mapModules ./overlays import) // {
        default = final: prev: {
          unstable = pkgs';
          my = self.packages.${system};
        };
      };

    packages."${system}" = mapModules ./packages (p: pkgs.callPackage p {});

    nixosModules = {
        snowflake = import ./.;
      } // mapModulesRec ./modules import;

    nixosConfigurations = mapHosts ./hosts {};

    devShells."${system}".default = import ./shell.nix {inherit pkgs;};

    templates.full = {
        path = ./.;
        description = "λ well-tailored and configureable NixOS system!";
      } // import ./templates;

    templates.default = self.templates.full;

    # TODO: deployment + template tool.
    # apps."${system}" = {
    #   type = "app";
    #   program = ./bin/hagel;
    # };
  };
}
