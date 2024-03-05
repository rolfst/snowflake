_: pkgs: {
  unstablePynvim = pkgs.python3Packages.pynvim.overrideAttrs {
    oldAttrs: rec {
        version = "0.5.0";
        repo = "python-client";
        rev = "unstable";
        sha256 = "";
      };
    }
  };
}
