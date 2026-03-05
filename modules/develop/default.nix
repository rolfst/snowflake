{
  lib,
  ...
}: {
  options.modules.develop = let
    inherit (lib.options) mkEnableOption;
  in {xdg.enable = mkEnableOption "XDG-related conf" // {default = true;};};
}
