{ pkgs ? import <nixpkgs> {} }:

let
  identity_upstream = pkgs.callPackage (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dogeorg/dogebox-nur-packages/1112abf7b364c620192ccc3d92c0c99ec3890071/pkgs/identity/default.nix";
    sha256 = "sha256-NDMxR+jpSZLosvwAFmFGektItf2iRclI1pshBaHJHXc=";
  }) {};

  ui = pkgs.fetchgit {
    url = "https://github.com/dogeorg/identity-ui.git";
    rev = "febddda2596b88be175ac57e29384cbe427ee53f";
    sha256 = "sha256-xvm0O7+PLBHjPZVDLx5jkQO2Wja4dcgj26DA5hd7cRc=";
  };

  identity = pkgs.writeScriptBin "run.sh" ''
    #!${pkgs.bash}/bin/bash
    export KEY=`cat /storage/delegated.key`
    ${identity_upstream}/bin/identity --bind ''${DBX_PUP_IP} --web ${ui}/src --dir /storage
  '';
in
{
  inherit identity;
}
