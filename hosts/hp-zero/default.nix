{
  pkgs,
  config,
  lib,
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
        git.enable = true;
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
        configFile = /home/rolfst/.config/openvpn/company.ovpn;
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
    };

    # virtualize = {
    #   enable = true;
    # };
    themes.active = "rose-pine";

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
        steam.enable = false;
        steam.hardware.enable = false;
        youtube.enable = true;
      };

      toolset = {
        citrix.enable = false;
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
    };
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
