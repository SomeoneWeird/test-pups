{ pkgs ? import <nixpkgs> {} }:

let
  websiteFiles = pkgs.fetchFromGitHub {
    owner = "dogeorg";
    repo = "dogebox-retail";
    rev = "main";
    hash = "sha256-UqqkSJl0FMDgNLJgjFXigcMVfzag4GilSi8acPV8poE=";
  };

  services = {
    caddy = {
      enable = true;
      package = pkgs.caddy;
      extraConfig = ''
        :8090 {
          root * ${websiteFiles}/
          file_server
          handle_errors {
            respond "404"
          }
        }
      '';
    };
  };
in
{
  inherit services;
}
