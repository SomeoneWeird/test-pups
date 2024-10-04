{ pkgs ? import <nixpkgs> {} }:

let
  jampuppy = pkgs.callPackage (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dogeorg/dogebox-nur-packages/014fe49fe6b299c4ca1ff70608495629ec92b7bd/pkgs/jampuppy/default.nix";
    sha256 = "sha256-9wpQdZ8U9KhMq+0rxD5UPWQl+RAaqSjO5VyJAD1sxas=";
  }) {};

  ui = pkgs.fetchgit {
    url = "https://github.com/dogeorg/dogemap-ui.git";
    rev = "v0.0.1";
    sha256 = "sha256-Em/jnIUmY1P0WhHX+1W4ALAsIyjrZyMYazMaY7STf3Q=";
  };

  dogemap = pkgs.writeScriptBin "run.sh" ''
    #!${pkgs.bash}/bin/bash
    ${jampuppy}/bin/jampuppy -A index.html --dir ${ui} --host 0.0.0.0 --port 8080 --proxy '/dogenet http://''${DBX_IFACE_DOGENET_WEB_API_NODES_HOST}:''${DBX_IFACE_DOGENET_WEB_API_NODES_PORT}/dbx/dogenet-web-api-nodes'
  '';
in
{
  inherit dogemap;
}
