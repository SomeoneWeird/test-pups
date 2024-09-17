{ pkgs }:

let
  client = pkgs.stdenv.mkDerivation {
    name = "client";
    version = "1.0";

    buildInputs = [ pkgs.go ];

    src = ./.;

    unpackPhase = "true";

    buildPhase = ''
      export GO111MODULE=off
      export GOCACHE=$(pwd)/.gocache
      mkdir -p $out/bin
      cd $src
      go build -o $out/bin/client client.go
    '';

    installPhase = ''
      echo "Binary built at $out/bin/client"
    '';
  };
in
{
  inherit client;
}
