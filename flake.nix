{
  inputs = {
    nixpkgs.url = "nixpkgs/7ff5e241a2b96fff7912b7d793a06b4374bd846c";
    ranz2nix = {
      url = "github:andir/ranz2nix";
      flake = false;
    };
    next-terminal = {
      url = "github:dushixiang/next-terminal";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, ranz2nix, next-terminal, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system; overlays = [
            self.overlay
          ];
          };
        in
        with pkgs;
        rec {
          packages = flake-utils.lib.flattenTree {
            next-terminal = pkgs.next-terminal;
          };
          defaultPackage = packages.next-terminal;
          checks = packages.next-terminal;
          devShell =
            let
              deploy = pkgs.writeShellScriptBin "deploy" ''
                ${pkgs.next-terminal}/bin/next-terminal --server.addr "$@" & \
                ${pkgs.next-terminal}/bin/guacd -b 127.0.0.1 -L info -f | parallel
              '';
            in
            mkShell {
              buildInputs = [ deploy ];
            };
        }
      ) // {
      overlay = final: prev: {
        next-terminal = with final;
          (
            let
              static =
                callPackage ./static.nix { inherit ranz2nix next-terminal; };
              guacamole = callPackage ./guacamole.nix { };
              src = pkgs.fetchFromGitHub {
                owner = "dushixiang";
                repo = "next-terminal";
                rev = next-terminal.rev;
                sha256 = next-terminal.narHash;
              };
            in
            buildGoModule {
              name = "next-terminal";
              inherit src;
              goPackagePath = "github.com/dushixiang/next-terminal";
              subPackages = [ "pkg" ];
              buildInputs = [ gcc pkgconfig ]
              ++ lib.optionals stdenv.isLinux [ stdenv.cc.libc.out ]
              ++ lib.optionals (stdenv.hostPlatform.libc == "glibc")
                [ stdenv.cc.libc.static ];
              vendorSha256 =
                "sha256-KWv5ErnsGILcIHu/HgXJTomQYYoFqNmxs1ZC6gQlfK0=";
              GOARCH =
                if stdenv.isDarwin then
                  "amd64"
                else if stdenv.hostPlatform.system == "i686-linux" then
                  "386"
                else if stdenv.hostPlatform.system == "x86_64-linux" then
                  "amd64"
                else if stdenv.isAarch32 then
                  "arm"
                else
                  throw "Unsupported system";
              CC = if stdenv.isDarwin then "clang" else "cc";

              preConfigure = ''
                substituteInPlace pkg/api/routes.go \
                --replace "web/build/index.html" "$out/web/build/index.html" \
                --replace "web/build/static" "$out/web/build/static" \
                --replace "web/build/favicon.ico" "$out/web/build/favicon.ico" \
                --replace "web/build/logo.svg" "$out/web/build/logo.svg"
              '';

              buildPhase = ''
                go build
              '';

              installPhase = ''
                mkdir -p $out/{bin,web}
                cp -r ${static} $out/web/build
                cp -r next-terminal $out/bin/next-terminal
                ln -s ${guacamole}/sbin/guacd $out/bin/guacd
              '';

            }
          );
      };
    };
}
