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
      git.enable = true;
      gnupg.enable = true;
    };

    networking = {
      networkManager.enable = true;
    };

    services = {ssh.enable = true;};

    develop = {
      dart.enable = false;
      haskell.enable = true;
      python.enable = true;
      rust.enable = true;
    };

    themes.active = "tokyonight";

    desktop = {
      xmonad.enable = true;
      terminal = {
        default = "kitty";
        alacritty.enable = true;
      };
      editors = {
        default = "nvim";
        emacs.irkalla.enable = true;
        neovim.agasaya.enable = true;
      };
      browsers = {
        default = "firefox-devedition";
        ungoogled.enable = true;
        firefox.enable = true;
      };
      education = {
        memory.enable = true;
        vidcom.enable = true;
      };
      toolset = {
        player = {
          music.enable = true;
          video.enable = true;
        };
        social.base.enable = true;
      };
    };
  };
}
