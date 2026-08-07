{
  lib,
  python3,
  makeWrapper,
}:

let
  python = python3.withPackages (ps: with ps; [
    google-api-python-client
    google-auth-oauthlib
    google-auth-httplib2
  ]);
in
python3.pkgs.buildPythonApplication {
  pname = "gemini-intake";
  version = "1.0.0";
  format = "other";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  propagatedBuildInputs = with python3.pkgs; [
    google-api-python-client
    google-auth-oauthlib
    google-auth-httplib2
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/gemini-intake
    cp ${./gemini_intake.py} $out/lib/gemini-intake/gemini_intake.py

    mkdir -p $out/bin
    makeWrapper ${python}/bin/python3 $out/bin/gemini-intake \
      --add-flags "$out/lib/gemini-intake/gemini_intake.py"

    runHook postInstall
  '';

  meta = {
    description = "Monitor Google Drive for Gemini chat exports and download to local inbox";
    mainProgram = "gemini-intake";
  };
}
