{ config, pkgs, lib, ... }:
let
  pi-coding-agent = pkgs.buildNpmPackage rec {
    pname = "pi-coding-agent";
    version = "0.80.3";
    src = pkgs.fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      rev = "v${version}";
      hash = "sha256-wQTrWKsb2HCGwzSAFEk8NWSDpqxSY/lv1/R6ghcmbaA=";
    };
    npmDepsHash = "sha256-geh8LH88OZybFXkR/jDeTdew6TNMdFM6jhCSYKn//dU=";
    npmRebuildFlags = [ "--ignore-scripts" ];
    npmBuildScript = "build";
    npmWorkspace = "packages/coding-agent";
    buildPhase = ''
      runHook preBuild
      npx tsgo -p packages/ai/tsconfig.build.json
      npx tsgo -p packages/tui/tsconfig.build.json
      npx tsgo -p packages/agent/tsconfig.build.json
      npm run build --workspace=packages/coding-agent
      runHook postBuild
    '';
    dontStrip = true;
    nativeBuildInputs = with pkgs; [
      makeBinaryWrapper
      python3
      versionCheckHook
    ];
    buildInputs = with pkgs; [
      nodejs_24
    ];
    env.NIX_MAIN_PROGRAM = "pi";
    env.NIX_NPM_FETCHER_VERSION = "1";
    versionCheckProgram = "${placeholder "out"}/bin/pi";
    versionCheckProgramArg = "--version";
    postInstall = ''
      local nm="$out/lib/node_modules/pi-monorepo/node_modules"
      for ws in @earendil-works/pi-ai:packages/ai \
                @earendil-works/pi-agent-core:packages/agent \
                @earendil-works/pi-tui:packages/tui; do
        IFS=: read -r pkg src <<< "$ws"
        rm "$nm/$pkg"
        cp -r "$src" "$nm/$pkg"
      done
      find "$nm" -type l -lname '*/packages/*' -delete
      find "$nm/.bin" -xtype l -delete
    '';
    postFixup = ''
      wrapProgram $out/bin/pi \
        --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep pkgs.fd ]}
    '';
    meta = {
      mainProgram = "pi";
    };
  };
in
{
  options = {
    dpom-pi.enable = lib.mkEnableOption "Add pi coding agent";
  };
  config = lib.mkIf config.dpom-pi.enable {
    home.packages = [ pi-coding-agent ];
  };
}
