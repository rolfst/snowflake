{
  description = "λ simple and configureable Nix-Flake repository!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      # url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flatpak
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.4.1";

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
    # hyprland.url = "github:hyprwm/Hyprland";
    xmonad = {
      url = "github:xmonad/xmonad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xmonad-contrib = {
      # url = "github:xmonad/xmonad-contrib"; # TODO: replace with official after #582 == merged!;
      url = "github:icy-thought/xmonad-contrib"; # TODO: replace with official after #582 == merged!;
      inputs.nixpkgs.follows = "xmonad";
    };

    picom = {
      url = "github:yshui/picom";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Toolset ++ Application(s)
    rust.url = "github:oxalica/rust-overlay";

    nvim-dir = {
      # url = "https://rolfst@github.com/rolfst/nvim.git?rev=8bc81eb5c440f832191844458329063586d97511";
      url = "https://github.com/rolfst/nvim.git";
      type = "git";
      submodules = true;
      flake = false;
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
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
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
        config.allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "calibre"
            "unrar"
          ];

        config.permittedInsecurePackages = [
          "electron-25.9.0"
        ];
        overlays = extraOverlays ++ (lib.attrValues self.overlays);
      };
    pkgs = mkPkgs nixpkgs [self.overlays.default];
    pkgs-unstable = mkPkgs nixpkgs-unstable [];

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
          unstable = pkgs-unstable;
          my = self.packages.${system};
        };

        nvfetcher = final: prev: {
          sources =
            builtins.mapAttrs (_: p: p.src)
            ((import ./packages/_sources/generated.nix) {
              inherit (final) fetchurl fetchgit fetchFromGitHub dockerTools;
            });
        };
      };

    packages."${system}" = mapModules ./packages (p: pkgs.callPackage p {});

    nixosModules =
      {
        snowflake = import ./.;
      }
      # // mapModulesRec ./modules import;
      ;

    nixosConfigurations = mapHosts ./hosts {};
    homeConfigurations = {
      cleo = nixosConfigurations.cleo.config.home-manager.users.${nixosConfigurations.cleo.config.user.name}.home;
    };

    devShells."${system}".default = import ./shell.nix {inherit lib pkgs;};

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
