{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [./hardware-configuration.nix];

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
      dart.enable = true;
      haskell.enable = true;
      python.enable = true;
      rust.enable = true;
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
        neovim.agasaya.enable = true;
      };
      browsers = {
        default = "firefox-devedition";
        ungoogled.enable = true;
        firefox.enable = true;
      };
      # education = {
      #   memory.enable = true;
      #   vidcom.enable = true;
      # };
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
