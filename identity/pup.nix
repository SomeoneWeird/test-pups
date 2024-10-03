{ pkgs ? import <nixpkgs> {} }:

let
  identity_upstream = pkgs.callPackage (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dogeorg/dogebox-nur-packages/49efa12c50aa522df81f3fe4501efea9a0fdc01c/pkgs/identity/default.nix";
    sha256 = "sha256-J3MsKK4Ir1g/YjIcJoa9OTepenw+5yjmqWi/x9l06ag=";
  }) {};

  ui = pkgs.fetchgit {
    url = "https://github.com/dogeorg/identity-ui.git";
    rev = "febddda2596b88be175ac57e29384cbe427ee53f";
    sha256 = "sha256-xvm0O7+PLBHjPZVDLx5jkQO2Wja4dcgj26DA5hd7cRc=";
  };

  combinedFiles = pkgs.stdenv.mkDerivation {
    name = "identity-combined-files";
    src = identity_upstream;

    buildInputs = [ pkgs.bash ];

    # installPhase = ''
    #   mkdir -p $out/bin/web
    #   mkdir -p $out/bin/storage
    #   cp -r ${identity_upstream}/* $out/
    #   cp -r ${ui}/src/* $out/bin/web/
    # '';
  };

  identity = pkgs.writeScriptBin "run.sh" ''
    #!${pkgs.bash}/bin/bash
    mkdir -p /storage/storage/web
    cp -r ${ui}/src/* /storage/storage/web
    cd /storage
    KEY=3aa47e2a7527ee7282c965c202c10ac1eaba2695b6ed508f979378df833c6648 ${combinedFiles}/bin/identity
  '';
in
{
  inherit identity;
}
