{ pkgs ? import <nixpkgs> {} }:

let
  dogenet_upstream = pkgs.callPackage (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dogeorg/dogebox-nur-packages/a5ced70296e017747bc3ffc73b52b8a100391c39/pkgs/dogenet/default.nix";
    sha256 = "sha256-i9JPkCW0iYYnBytQAm2JHmWsnF9MnwazZ9UfG+LRHq4=";
  }) {};

  dogenet = pkgs.writeScriptBin "run.sh" ''
    #!${pkgs.bash}/bin/bash
    export KEY=`cat /storage/delegated.key`
    IP=`${pkgs.curl}/bin/curl https://reflector.dogecoin.org/me | ${pkgs.jq}/bin/jq -r .ip`
    cp ${dogenet_upstream}/bin/storage/dbip-city-ipv4-num.csv /storage
    ${dogenet_upstream}/bin/dogenet --handler ''${DBX_PUP_IP}:42068 --web ''${DBX_PUP_IP}:8080 --public ''${IP}:42069 --dir /storage
  '';
in
{
  inherit dogenet;
}
