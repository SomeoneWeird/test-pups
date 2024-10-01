{ pkgs ? import <nixpkgs> {} }:

let
  websiteFiles = pkgs.fetchFromGitHub {
    owner = "dogeorg";
    repo = "dogebox-retail";
    rev = "main";
    hash = "sha256-UqqkSJl0FMDgNLJgjFXigcMVfzag4GilSi8acPV8poE=";
  };

  shipper = pkgs.buildNpmPackage rec {
    name = "shipper";

    src = pkgs.fetchFromGitHub {
      owner = "dogeorg";
      repo = "shipper";
      rev = "main";
      hash = "sha256-5kb1mEIeb0ofN/ZfmUQE3wrdUrUH9fuDA/le+r2zTSM=";
    };

    npmDepsHash = "sha256-HkOddG+GFk9D9Yd8Nntar3vKn+RZBMIzDkVfhZrgi5c=";
  };

  baseOrderPageFilesZIP = pkgs.requireFile {
    name = "dogebox-order-page-main.zip";
    url = "https://github.com/dogeorg/dogebox-order-page/archive/refs/heads/main.zip";
    sha256 = "d3545bde3b37c1534add39fa8ba453d3308c9d46f16119058e2c08261220dbd7";
  };

  baseOrderPageFiles = pkgs.stdenv.mkDerivation {
    name = "dogebox-order-page-unzipped";
    src = baseOrderPageFilesZIP;
    nativeBuildInputs = [ pkgs.unzip ];
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p $out
      cp -R dogebox-order-page-main/* $out/
    '';
  };

  orderPageFiles = pkgs.stdenv.mkDerivation {
    name = "order-page-files";
    src = baseOrderPageFiles;

    buildInputs = [ pkgs.bash ];

    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
      rm $out/conf.php
      cat > $out/conf.php <<EOF
<?php

header('Access-Control-Allow-Origin: *');
//ini_set('display_errors', 1);

// GigaWallet Server configuration
// Attenttion **
// Subscribe on GigaWallet for PAYMENT_RECEIVED to /callback/ to update payments
// Attenttion **
\$config["gigawallet"] = 1; // enable GigaWallet
\$config["GigaServer"][0] = "10.69.0.3"; // admin server
\$config["GigaPort"][0] = 8081; // admin server port
\$config["GigaServer"][1] = "10.69.0.3"; // public server
\$config["GigaPort"][1] = 8082; // public server port
\$config["GigaDust"] = 0; // GigaWallet deduct dust to the payment to be able to send it successfully because of network fees
\$config["payout_address"] = "Dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"; // Dogecoin payout address to move to a secure wallet

// MariaDB Server configuration
\$config["dbhost"] = "localhost"; 
\$config["dbuser"] = "pup";
# \$config["dbpass"] = "shuchpass";
\$config["dbname"] = "dogebox";
\$config["dbport"] = 3306;

// SMTP Email Server Configuration
\$config["mail_name_from"] = "DogeBox"; // name to show on all emails sent
\$config["email_from"] = "no-reply@doge-box.com"; // email to show and reply on all emails sent
\$config["email_reply_to"] = "no-reply@doge-box.com"; // email to reply
\$config["email_port"] = 465;
\$config["email_password"] = "shuchpass";
\$config["email_stmp"] = "mail.doge-box.com";

// Shipper Server Configuration
\$config["shipperHost"] = 'http://localhost:3000';
EOF
    '';
  };

  services = {
    mysql = {
      enable = true;
      package = pkgs.mysql;
      dataDir = "/storage";
      user = "pup";
      group = "pup";
      initialDatabases = [
        {
          name = "dogebox";
          schema = "${orderPageFiles}/shibes.sql";
        }
      ];
      ensureUsers = [
        {
          name = "pup";
          ensurePermissions = {
            "dogebox.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    phpfpm = {
      phpPackage = pkgs.php;
      pools.www = {
        user = "pup";
        group = "pup";
        listen = "/run/php-fpm/www.sock";
      };
    };

    caddy = {
      user = "pup";
      group = "pup";
      enable = true;
      package = pkgs.caddy;
      extraConfig = ''
        :8090 {
          handle_path /order/* {
            root * ${orderPageFiles}/
            php_fastcgi /run/php-fpm/www.sock
            file_server
          }

          handle {
            root * ${websiteFiles}/
            file_server
          }

          handle_errors {
            respond "404"
          }
        }
      '';
    };
  };
in
{
  inherit services shipper orderPageFiles;
}
