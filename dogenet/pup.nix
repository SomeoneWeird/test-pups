{ pkgs ? import <nixpkgs> {} }:

let
  dogenet_upstream = pkgs.callPackage (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dogeorg/dogebox-nur-packages/014fe49fe6b299c4ca1ff70608495629ec92b7bd/pkgs/dogenet/default.nix";
    sha256 = "sha256-gthnX5qJHMCH4BILvMMdXpCf+ycj4qaTbVkaYmdEytg=";
  }) {};

  dogenet = pkgs.writeScriptBin "run.sh" ''
    #!${pkgs.bash}/bin/bash
    ${dogenet_upstream}/bin/dogenet
  '';
in
{
  inherit dogenet;
}
