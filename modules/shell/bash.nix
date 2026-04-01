{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
in
{
  options.modules.shell.bash =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "bash shell" // {
        default = true;
      };
    };

  config = mkIf config.modules.shell.bash.enable {
    # Enable starship-rs:
    modules.shell.starship.enable = true;
    hm.programs.starship.enableBashIntegration = true;

    hm.programs.bash = {
      enable = true;
      historySize = 5000;
      historyFileSize = 5000;
      historyIgnore = [
        "btm"
        "htop"
        "neofetch"
      ];
      shellAliases = {
        ls = "eza -Slhg --icons";
        lsa = "zxa -Slhga --icons";
        less = "less -R";
        wup = "systemctl start wg-quick-Akkadian-VPN.service";
        wud = "systemctl stop wg-quick-Akkadian-VPN.service";
        y = "yazi";
      };
      bashrcExtra = ''
        # -------===[ Useful Functions ]===------- #
        function sysup {
            nixos-rebuild switch --sudo --flake .#"$(hostname)"
        }

        # -------===[ External Plugins ]===------- #
        eval "$(starship init bash)"
        eval "$(direnv hook bash)"
      '';
    };
  };
}
