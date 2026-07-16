{
  lib,
  buildNpmPackage,
  bun,
  makeWrapper,
  google-chrome,
  rsync,
}:

buildNpmPackage rec {
  pname = "browser-tools";
  version = "1.0.0";

  src = ./.;

  npmDepsHash = "sha256-oLbKcVM1rk5fma9vEre51PukYmLvDkDnHgSmwq3L5sE=";

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper bun ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/browser-tools
    cp -r node_modules $out/lib/browser-tools/
    cp *.js $out/lib/browser-tools/
    cp package.json $out/lib/browser-tools/
    cp README.md $out/lib/browser-tools/

    mkdir -p $out/bin
    for script in $out/lib/browser-tools/browser-*.js; do
      name=$(basename "$script" .js)
      makeWrapper ${bun}/bin/bun $out/bin/$name \
        --add-flags "$script" \
        --prefix PATH : ${lib.makeBinPath [ google-chrome rsync ]}
    done

    runHook postInstall
  '';

  meta = {
    description = "Minimal browser tools for scraping with persistent sessions via CDP";
    mainProgram = "browser-start";
  };
}
