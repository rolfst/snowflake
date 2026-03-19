{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  d2,
  typst,
}:

buildGoModule rec {
  pname = "typst-d2-mcp";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "dlouwers";
    repo = "typst-d2-mcp";
    rev = "v${version}";
    hash = "sha256-5NiBftyTT0OVMnY4L3hgd+kLWYeOOa+Wrmg38KLTJuk=";
  };

  vendorHash = "sha256-PmhVBQhBd00+YaMhvjtqjCQaeez2oTljpzNqrRakfWY=";

  subPackages = [
    "cmd/typst-d2-prep"
    "cmd/typst-d2-mcp"
  ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
    "-X main.serverVersion=${version}"
  ];

  env.CGO_ENABLED = 0;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/typst-d2-prep \
      --prefix PATH : ${lib.makeBinPath [ d2 typst ]}
    wrapProgram $out/bin/typst-d2-mcp \
      --prefix PATH : ${lib.makeBinPath [ d2 typst ]}
  '';

  meta = with lib; {
    description = "D2 diagram rendering for Typst documents via CLI preprocessor and MCP server";
    homepage = "https://github.com/dlouwers/typst-d2-mcp";
    license = licenses.mit;
    mainProgram = "typst-d2-mcp";
  };
}
