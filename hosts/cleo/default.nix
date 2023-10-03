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
      android.enable = false;
      tmux.enable = true;
    };
    hardware.xkbLayout = {hyperCtrl.enable = true;};
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
        neovim.rolfst.enable = true;
      };
      browsers = {
        default = "firefox";
        ungoogled.enable = true;
        firefox.enable = true;
      };
      extensions = {
        keybase.enable = true; # the gui
      };
      education = {
        #   memory.enable = true;
        vidcom.enable = false;
      };

      toolset = {
        player = {
          music.enable = false;
          video.enable = false;
        };
        docView = {
          zathura.enable = false;
          sioyek.enable = false;
        };
        social = {
          base.enable = true;
          discord.enable = false;
          slack.enable = true;
        };
        keybase.enable = true;
      };
    };
  };
}
