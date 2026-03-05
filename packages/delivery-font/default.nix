{ stdenv, lib }:

stdenv.mkDerivation {
  pname = "delivery-font";
  version = "2.500";

  src = ./fonts;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp $src/*.ttf $out/share/fonts/truetype/
  '';

  meta = with lib; {
    description = "Delivery font family";
    platforms = platforms.all;
  };
}
