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
    sha256 = "de9263814bd9bf44b8ed27945e1a908303ebc0c44248238862ca50d1acb153f1";
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
      ln -s /storage/conf.php $out/conf.php

    cat > $out/frankenphpconfig.json <<EOF
{"admin":{"disabled":true},"apps":{"frankenphp":{},"http":{"servers":{"srv0":{"listen":[":8089"],"routes":[{"handle":[{"handler":"vars","root":"/nix/store/kgsh1f8mkj6wmw14z3vgzf3amil87ls4-order-page-files/"},{"encodings":{"br":{},"gzip":{},"zstd":{}},"handler":"encode","prefer":["zstd","br","gzip"]}]},{"match":[{"file":{"try_files":["{http.request.uri.path}/index.php"]},"not":[{"path":["*/"]}]}],"handle":[{"handler":"static_response","headers":{"Location":["{http.request.orig_uri.path}/"]},"status_code":308}]},{"match":[{"file":{"try_files":["{http.request.uri.path}","{http.request.uri.path}/index.php","index.php"],"split_path":[".php"]}}],"handle":[{"handler":"rewrite","uri":"{http.matchers.file.relative}"}]},{"match":[{"path":["*.php"]}],"handle":[{"handler":"php","split_path":[".php"]}]},{"handle":[{"handler":"file_server"}]},{"handle":[{"handler":"file_server","hide":["/nix/store/7gfnjbxanzwcxnm4wvh8m37bksh54y03-order-page-files/frankenphpconfig"]}]}]}}}}}
EOF

# Above is adapted from the below with `frankenphp adopt <file> --adapter caddyfile` and then modified to disable admin
# {
#   frankenphp
#   order php_server before file_server
# }

# :8089 {
#   encode zstd br gzip
#   root * /nix/store/kgsh1f8mkj6wmw14z3vgzf3amil87ls4-order-page-files/
#   php_server
#   file_server
# }
    '';
  };

  orderPage = pkgs.writeScriptBin "run.sh" ''
    #!/run/current-system/sw/bin/bash

      cat > /storage/conf.php <<EOF
<?php

header('Access-Control-Allow-Origin: *');
//ini_set('display_errors', 1);

\$config['orderHost'] = 'https://localhost/order/';

// GigaWallet Server configuration
// Attenttion **
// Subscribe on GigaWallet for PAYMENT_RECEIVED to /callback/ to update payments
// Attenttion **
\$config["gigawallet"] = 1; // enable GigaWallet
\$config["GigaServer"][0] = "''${DBX_IFACE_GIGAWALLET_ADMIN_HOST}"; // admin server
\$config["GigaPort"][0] = ''${DBX_IFACE_GIGAWALLET_ADMIN_PORT}; // admin server port
\$config["GigaServer"][1] = "''${DBX_IFACE_GIGAWALLET_PUBLIC_HOST}"; // public server
\$config["GigaPort"][1] = ''${DBX_IFACE_GIGAWALLET_PUBLIC_PORT}; // public server port
\$config["GigaDust"] = 0; // GigaWallet deduct dust to the payment to be able to send it successfully because of network fees
\$config["payout_address"] = "Dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"; // Dogecoin payout address to move to a secure wallet

// MariaDB Server configuration
\$config["dbHost"] = "localhost"; 
\$config["dbUser"] = "pup";
# \$config["dbPass"] = "shuchpass";
\$config["dbName"] = "dogebox";
\$config["dbPort"] = 3306;

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

    ${pkgs.frankenphp}/bin/frankenphp run --config ${orderPageFiles}/frankenphpconfig.json
  '';

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

    caddy = {
      user = "pup";
      group = "pup";
      enable = true;
      package = pkgs.caddy;
      extraConfig = ''
        :8090 {
          @order {
            path /order/*
          }

          handle @order {
            uri strip_prefix /order
            reverse_proxy 127.0.0.1:8089
          }

          handle {
            root * ${websiteFiles}/
            file_server
          }
        }
      '';
    };
  };
in
{
  inherit services shipper orderPage;
}
