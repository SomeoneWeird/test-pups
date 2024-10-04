{ pkgs ? import <nixpkgs> {} }:

let
  identity_upstream = pkgs.callPackage (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dogeorg/dogebox-nur-packages/cf3b45f3beb1b15366544058582b69907050970a/pkgs/identity/default.nix";
    sha256 = "sha256-tydl+uqFPkslnXJdg9Imcbh4ZmzpIDbKEBkUiPa3L18=";
  }) {};

  ui = pkgs.fetchgit {
    url = "https://github.com/dogeorg/identity-ui.git";
    rev = "febddda2596b88be175ac57e29384cbe427ee53f";
    sha256 = "sha256-xvm0O7+PLBHjPZVDLx5jkQO2Wja4dcgj26DA5hd7cRc=";
  };

  identity = pkgs.writeScriptBin "run.sh" ''
    #!${pkgs.bash}/bin/bash
    export KEY=`cat /storage/delegated.key`
    ${identity_upstream}/bin/identity --bind ''${DBX_PUP_IP}:8099 --web ${ui}/src --dir /storage --handler ''${DBX_IFACE_DOGENET_HANDLER_HOST}:''${DBX_IFACE_DOGENET_HANDLER_PORT}
  '';
in
{
  inherit identity;
}
