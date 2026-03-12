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
      default = "zsh";
      android.enable = false;
      tmux.enable = true;
      mise.enable = true;
      toolset = {
        fzf.enable = true;
        scm.enable = true;
        AI.enable = true;
        fastfetch.enable = true;
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
      haskell.enable = true;
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
      virtual.wine.enable = true;
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
        default = "firefox";
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
        steam.enable = true;
        steam.hardware.enable = true;
        youtube.enable = true;
      };

      toolset = {
        citrix.enable = false;
        player = {
          music.enable = false;
          video.enable = true;
        };
        readers = {
          zathura.enable = true;
          sioyek.enable = false;
          calibre.enable = true;
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
    };
  };
  age.secrets."private-tokens" = {
    file = "${inputs.self}/secrets/private-tokens.age";
    owner = config.user.name;
    group = config.user.group;
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
