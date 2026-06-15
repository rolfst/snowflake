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
  options.modules.shell.starship =
    let
      inherit (lib.options) mkEnableOption;
    in
    {
      enable = mkEnableOption "minimal shell ricing";
    };

  config = mkIf config.modules.shell.starship.enable {
    hm.programs.starship = {
      enable = true;
      settings =
        let
          inherit (config.modules.themes.colors.main) normal bright types;
        in
        {
          palette = "noctalia";
          scan_timeout = 10;
          add_newline = true;
          line_break.disabled = true;

          format = "[$directory](fg:blue) ($git_branch)($git_status )($nix_shell)($character)";
          right_format = "[$cmd_duration](bg:none fg:magenta)";

          cmd_duration = {
            min_time = 1;
            format = "[ $duration]($style)";
            disabled = false;
            style = "bg:magenta fg:bg";
          };

          directory = {
            format = "[  $path]($style)";
            style = "bg:blue fg:fg bold";
            truncation_length = 2;
            truncation_symbol = "…/";
          };

          git_branch = {
            format = "[[](fg:border)( $branch)[](fg:border)]($style) ";
            style = "bg:border fg:fg bold";
          };

          git_status = {
            format = "[([](fg:panelbg)( 『 $all_status$ahead_behind 』)[](fg:panelbg))]($style)";
            style = "bg:panelbg fg:bg bold";
          };

          character = {
            error_symbol = "[](red)";
            success_symbol = "[](green)";
            vicmd_symbol = "[](blue)";
          };

          nix_shell = {
            disabled = false;
            impure_msg = "[impure](red)";
            pure_msg = "[pure](green)";
            format = "via [$symbol$state( \\($name\\))]($style) ";
            style = "blue";
            symbol = "[λ ](panelbg)";
          };

          battery = {
            full_symbol = "🔋";
            charging_symbol = "⚡️";
            discharging_symbol = "💀";
            display = [
              {
                style = "red";
                threshold = 15;
              }
            ];
          };

          palettes.noctalia = {
            # Standard terminal colors
            black = normal.black;
            red = normal.red;
            green = normal.green;
            yellow = normal.yellow;
            blue = normal.blue;
            magenta = normal.magenta;
            cyan = normal.cyan;
            white = normal.white;
            # Bright variants
            bright-black = bright.black;
            bright-red = bright.red;
            bright-green = bright.green;
            bright-yellow = bright.yellow;
            bright-blue = bright.blue;
            bright-magenta = bright.magenta;
            bright-cyan = bright.cyan;
            bright-white = bright.white;
            # Semantic
            bg = types.bg;
            fg = types.fg;
            panelbg = types.panelbg;
            border = types.border;
          };
        };
    };
  };
}
