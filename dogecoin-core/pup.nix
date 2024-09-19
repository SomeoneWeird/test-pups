{ pkgs }:

let
  storageDirectory = "/storage";
  dogecoind_bin = pkgs.callPackage (pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dogeorg/dogebox-nur-packages/19de423874c3258fae756933d30482ff74605cee/pkgs/dogecoin-core/default.nix";
    sha256 = "sha256-A1GA/dJee2YBs5b4prxHPr5WQfnuTTD7EX/iy9ufxYA=";
  }) {};

  dogecoind = pkgs.writeScriptBin "run.sh" ''
    #!${pkgs.stdenv.shell}
    if [ ! -f /storage/rpcuser.txt ] || [ ! -f /storage/rpcpassword.txt ]; then
        RPCUSER=$(${pkgs.openssl}/bin/openssl rand -base64 10 | tr -dc 'a-zA-Z0-9' | head -c 10)
        RPCPASS=$(${pkgs.openssl}/bin/openssl rand -base64 20 | tr -dc 'a-zA-Z0-9' | head -c 20)

        echo "$RPCUSER" > /storage/rpcuser.txt
        echo "$RPCPASS" > /storage/rpcpassword.txt
    else
        RPCUSER=$(cat /storage/rpcuser.txt)
        RPCPASS=$(cat /storage/rpcpassword.txt)
    fi
    
    ${dogecoind_bin}/bin/dogecoind -datadir=${storageDirectory} -rpcuser=$RPCUSER -rpcpassword=$RPCPASS
  '';

  monitor = pkgs.buildGoModule {
    pname = "monitor";
    version = "0.0.1";
    src = ./monitor;
    vendorHash = null;

    systemPackages = [ dogecoind_bin ];
    
    buildPhase = ''
      export GO111MODULE=off
      export GOCACHE=$(pwd)/.gocache
      go build -ldflags "-X main.pathToDogecoind=${dogecoind_bin}" -o monitor monitor.go
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp monitor $out/bin/
    '';
  };

  logger = pkgs.buildGoModule {
    pname = "logger";
    version = "0.0.1";
    src = ./logger;
    vendorHash = null;

    buildPhase = ''
      export GO111MODULE=off
      export GOCACHE=$(pwd)/.gocache
      go build -ldflags "-X main.storageDirectory=${storageDirectory}" -o logger logger.go
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp logger $out/bin/
    '';
  };
in
{
  inherit dogecoind monitor logger;
}
