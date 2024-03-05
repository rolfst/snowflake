_: pkgs: {
  neovim = pkgs.neovim.overrideAttrs (
    oldAttrs: rec {
        pynvim = pkgs.unstable.pynvim
        neovim = pkgs.neovim.override {
            extraPython3Packages = [pkgs.unstable.python3Packages.pynvim]
        }
  );
}
