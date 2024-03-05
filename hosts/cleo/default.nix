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
      gnupg.enable = true;
      android.enable = false;
      tmux.enable = true;
      toolset = {
        fzf.enable = true;
        git.enable = true;
      };
    };
    hardware = {
      xkbLayout = {
        hyperCtrl.enable = true;
      };
      printer.enable = true;
      bluetooth.enable = true;
    };
    networking = {
      networkManager.enable = true;
    };

    services = {
      ssh.enable = true;
    };

    develop = {
      node.enable = true;
      haskell.enable = true;
      python.enable = true;
      rust.enable = true;
      lua.enable = true;
      java.enable = true;
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
      };
      browsers = {
        default = "firefox";
        google.enable = true;
        firefox.enable = true;
      };
      extensions = {
        keybase.enable = true; # the gui
        "2fa".enable = true;
        screenshot.enable = true;
      };
      education = {
        memory.enable = true;
        vidcom.enable = false;
      };

      distraction = {
        steam.enable = true;
        steam.hardware.enable = true;
        youtube.enable = true;
      };

      toolset = {
        player = {
          music.enable = false;
          video.enable = false;
        };
        docView = {
          zathura.enable = true;
          sioyek.enable = false;
        };
        social = {
          base.enable = true;
          matrix.withClient.enable = true;
          discord.enable = true;
          slack.enable = true;
        };
        keybase.enable = true;
      };
    };
    virtualize = {
      enable = true;
      podman.enable = true;
    };
  };
}
