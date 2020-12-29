{
  inputs = {
    nixpkgs.url = "nixpkgs/7ff5e241a2b96fff7912b7d793a06b4374bd846c";
    ranz2nix = { url = "github:andir/ranz2nix"; flake = false;};
    next-terminal = { url = "github:dushixiang/next-terminal"; flake = false;};
  };

  outputs = inputs@{ self, nixpkgs, ranz2nix, next-terminal }: {
    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux";};
      let
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
          subPackages = [ "pkg" ];          #subPackages = [ "cmd/photoprism" ];
          buildInputs = [ gcc pkgconfig ]
              ++ lib.optionals stdenv.isLinux [ stdenv.cc.libc.out ]
              ++ lib.optionals (stdenv.hostPlatform.libc == "glibc") [ stdenv.cc.libc.static ];
          vendorSha256 = "sha256-vquM0tDepFwQjNFJrkZylpXtdegPuY3vVaqp/52o4SA=";
          GOARCH = if stdenv.isDarwin then "amd64"
                   else if stdenv.hostPlatform.system == "i686-linux" then "386"
                   else if stdenv.hostPlatform.system == "x86_64-linux" then "amd64"
                   else if stdenv.isAarch32 then "arm"
                   else throw "Unsupported system";
          CC = if stdenv.isDarwin then "clang" else "cc";
          buildPhase = ''
          go build
          '';
          installPhase = ''
          mkdir -p $out/bin
          next-terminal $out/bin/next-terminal
          '';
        };
  };
}
