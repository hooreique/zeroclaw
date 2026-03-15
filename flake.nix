{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    llm-agents.url = "github:numtide/llm-agents.nix/3a768998497f3cc4cc9ca20480b7f82a02222828";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      llm-agents,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        version = "0.6.5";
        src = ./.;

        zeroclaw-web = pkgs.buildNpmPackage {
          pname = "zeroclaw-web";
          version = version;
          src = ./web;
          npmDepsHash = "sha256-RMiFoPj4cbUYONURsCp4FrNuy9bR1eRWqgAnACrVXsI=";
          installPhase = ''
            runHook preInstall
            cp -r dist $out
            runHook postInstall
          '';
        };

        zeroclaw = pkgs.rustPlatform.buildRustPackage {
          pname = "zeroclaw";
          inherit version src;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          cargoHash = "sha256-1/s2ijYqanhHIsYSw85c4H3T5phnAfvV7oQeAl/6lxQ=";

          postPatch = ''
            mkdir -p web
            ln -s ${zeroclaw-web} web/dist
          '';

          doCheck = false;

          postFixup = ''
            wrapProgram $out/bin/zeroclaw \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.w3m-nographics ]}
          '';

          meta = {
            description = "Fast, small, and fully autonomous AI assistant infrastructure - deploy anywhere, swap anything";
            homepage = "https://github.com/zeroclaw-labs/zeroclaw";
            license = pkgs.lib.licenses.mit;
            mainProgram = "zeroclaw";
          };
        };

        codex = llm-agents.packages.${system}.codex;
      in
      {
        packages = {
          inherit zeroclaw zeroclaw-web;
          default = zeroclaw;
        };
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.sqlite-interactive
            codex
          ];
        };
      }
    );
}
