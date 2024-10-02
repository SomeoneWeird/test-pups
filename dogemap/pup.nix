{ pkgs ? import <nixpkgs> {} }:

let
  jampuppy = pkgs.callPackage (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dogeorg/dogebox-nur-packages/014fe49fe6b299c4ca1ff70608495629ec92b7bd/pkgs/jampuppy/default.nix";
    sha256 = "sha256-9wpQdZ8U9KhMq+0rxD5UPWQl+RAaqSjO5VyJAD1sxas=";
  }) {};

  ui = pkgs.fetchgit {
    url = "https://github.com/dogeorg/dogemap-ui.git";
    rev = "3f83fe702ad955d9f654e3edf05201b2b9950388";
    sha256 = "sha256-xID2IDyT83xgQ0f9izbpCktUOjvEh95/9IVQ9WLwTwg=";
  };

  dogemap = pkgs.writeScriptBin "run.sh" ''
    #!${pkgs.bash}/bin/bash
    ${jampuppy}/bin/jampuppy -A index.html --dir ${ui} --host 0.0.0.0 --port 8080
  '';
in
{
  inherit dogemap;
}
