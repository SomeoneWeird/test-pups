{ pkgs }:

let
  server = pkgs.stdenv.mkDerivation {
    name = "server";
    version = "1.0";

    buildInputs = [ pkgs.go ];

    src = ./.;

    unpackPhase = "true";

    buildPhase = ''
      export GO111MODULE=off
      export GOCACHE=$(pwd)/.gocache
      mkdir -p $out/bin
      cd $src
      go build -o $out/bin/server server.go
    '';

    installPhase = ''
      echo "Binary built at $out/bin/server"
    '';
  };
in
{
  inherit server;
}