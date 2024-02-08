_: pkgs: {
  postman = pkgs.postman.overrideAttrs (
    oldAttrs: rec {
      version = "v10.22";
      pname = oldAttrs.pname;
      src = pkgs.fetchurl {
        url = "https://dl.pstmn.io/download/latest/linux_64";
        name = "postman-linux-x64.tar.gz";
        hash = "sha256-Ii6ScBPuYxyzH2cGSTuDlUFG3nS1rTLTGqXqVbz5Epo=";
      };
    }
  );
}
