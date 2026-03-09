{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ ./hardware.nix ];

  modules = {
    shell = {
      # Nushell as interactive shell via exec strategy:
      #   - zsh remains the login shell (sources /etc/profile for NixOS env setup)
      #   - zsh immediately exec's nushell for interactive use
      #   - All shell-abbr aliases ported: simple ones as shellAliases,
      #     complex ones (with !, pipes, subshells) as def commands wrapping bash
      #   - Aliases with '!' in the name (gc!, gca!, etc.) renamed to use '_' (gc_, gca_)
      #   - environment.shellAliases from develop modules (py, rs, ca, ya) ported to nushell
      #   - Podman aliases (pps, pclean, piclean) ported inline
      #   - Integrations: starship, zoxide, direnv, carapace (completions), mise
      #   - No nushell support: any-nix-shell (no nix-shell indicator), fzf keybindings
      #   - Escape hatch: run `NUSHELL_ACTIVE=1 zsh` to get a clean zsh session
      default = "nushell";
      android.enable = false;
      tmux.enable = true;
      mise.enable = true;
      toolset = {
        fzf.enable = true;
        scm.enable = true;
        AI.enable = true;
      };
    };
    hardware = {
      laptop.enable = true;
      xkbLayout = {
        hyperCtrl.enable = true;
      };
      printer.enable = true;
      bluetooth.enable = true;
      kmonad.enable = false;
    };
    networking = {
      networkManager.enable = true;
      openvpn = {
        enable = true;
        name = "company";
        configFile = config.age.secrets."company-vpn".path;
      };
    };

    services = {
      ssh.enable = true;
      flatpak.enable = true;
      streaming = {
        enable = true;
        sunshine.enable = true;
        tailscale.enable = true;
      };
    };

    develop = {
      node.enable = true;
      haskell.enable = false;
      python.enable = true;
      rust.enable = true;
      lua.enable = true;
      java.enable = true;
      cc.enable = true;
      xdg.enable = true;
      kubernetes.enable = true;
      cloud = {
        aws.enable = false;
        azure.enable = true;
      };
    };

    # virtualize = {
    #   enable = true;
    # };
    themes.active = "dark-pastel";

    desktop = {
      virtual = {
        wine.enable = true;
        winapps.enable = true;
      };
      xmonad.enable = false;
      niri.enable = true;
      terminal = {
        default = "kitty";
        kitty.enable = true;
      };
      editors = {
        default = "nvim";
        libreoffice.enable = true;
        neovim.rolfst.enable = true;
        vscodium.enable = true;
      };
      browsers = {
        default = "google";
        google.enable = true;
        firefox.enable = true;
        zen.enable = false;
      };
      extensions = {
        keybase.enable = true; # the gui
        screenshot.enable = true;
      };
      education = {
        memory.enable = true;
        vidcom.enable = true;
      };

      distraction = {
        steam.enable = false;
        steam.hardware.enable = false;
        youtube.enable = true;
      };

      toolset = {
        citrix.enable = true;
        player = {
          music.enable = false;
          video.enable = false;
        };
        readers = {
          zathura.enable = true;
          sioyek.enable = false;
          calibre.enable = false;
        };
        social = {
          base.enable = true;
          matrix.withClient.enable = true;
          discord.enable = true;
          slack.enable = true;
        };
        graphics = {
          raster.enable = true;
        };
        keybase.enable = true;
      };
    };
    virtualize = {
      enable = true;
      podman.enable = true;
      docker.enable = true;
      docker.daemonSettings = true;
    };
  };
  fonts.packages = [ pkgs.my."delivery-font" ];

  age.secrets."company-vpn" = {
    file = "${inputs.self}/secrets/company-vpn.ovpn.age";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  security.pki.certificateFiles = [
    ./rootCA.pem
  ];

  # specialisation = {
  #   "X11-XMonad" = {
  #     configuration = {
  #       system.nixos.tags = [ "xmonad" ];
  #       modules.desktop.niri.enable = lib.mkForce false;
  #       modules.desktop.xmonad.enable = lib.mkForce true;
  #     };
  #   };
  # };
}
