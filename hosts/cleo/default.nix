{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [./hardware.nix];

  modules = {
    shell = {
      default = "zsh";
      android.enable = false;
      tmux.enable = true;
      toolset = {
        fzf.enable = true;
        git.enable = true;
      };
    };
    hardware = {
      laptop.enable = true;
      xkbLayout = {
        hyperCtrl.enable = true;
      };
      printer.enable = true;
      bluetooth.enable = true;
      kmonad.enable = true;
    };
    networking = {
      networkManager.enable = true;
    };

    services = {
      ssh.enable = true;
      flatpak.enable = true;
    };

    develop = {
      node.enable = true;
      haskell.enable = true;
      python.enable = true;
      rust.enable = true;
      lua.enable = true;
      java.enable = true;
      cc.enable = true;
    };

    # virtualize = {
    #   enable = true;
    # };
    themes.active = "rose-pine";

    desktop = {
      xmonad.enable = true;
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
        zen.enable = true;
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
          video.enable = false;
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
      podman.enable = false;
      docker.enable = true;
    };
  };
}
