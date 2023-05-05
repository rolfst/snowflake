{ pkgs, config, lib, ... }: {
  imports = [./hardware-configuration.nix];

  modules = {
    shell = {
      default = "zsh";
      git.enable = true;
      gnupg.enable = true;
      android.enable = false;
      tmux.enable = true;
    };
    hardware.xkbLayout = { hyperCtrl.enable = true; };
    networking = {
      networkManager.enable = true;
    };

    services = {ssh.enable = true;};

    develop = {
      node.enable = true;
      haskell.enable = true;
      python.enable = true;
      rust.enable = true;
      lua.enable = true;
    };

    themes.active = "rose-pine";

    desktop = {
      xmonad.enable = true;
      terminal = {
        default = "kitty";
        kitty.enable = true;
      };
      editors = {
        default = "nvim";
        neovim.rolfst.enable = true;
      };
      browsers = {
        default = "firefox-devedition";
        ungoogled.enable = true;
        firefox.enable = true;
      };
      extensions = {
        keybase.enable = true; # the gui
      };
      education = {
      #   memory.enable = true;
        vidcom.enable = true;
      };

      toolset = {
        player = {
          music.enable = true;
          video.enable = true;
        };
        docView = {
          zathura.enable = true;
          sioyek.enable = true;
        };
        social.base.enable = true;
        keybase.enable = true;
      };
    };
  };
}
