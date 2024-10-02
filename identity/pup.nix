{ pkgs ? import <nixpkgs> {} }:

let
  identity_upstream = pkgs.callPackage (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dogeorg/dogebox-nur-packages/a17e79ba9bb59f2251e33777f020c27e8857ccb4/pkgs/identity/default.nix";
    sha256 = "sha256-jl2SNVsctnFbhKrSZMlcvu2BpYkFDxxvXjRYP1kdIBE=";
  }) {};

  identity = pkgs.writeScriptBin "run.sh" ''
    #!${pkgs.bash}/bin/bash
    ${identity_upstream}/bin/identity
  '';
in
{
  inherit identity;
}
