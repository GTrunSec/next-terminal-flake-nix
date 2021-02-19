{ stdenv
, lib
, nodejs-12_x
, runCommand
, callPackage
, fetchurl
, fetchFromGitHub
, next-terminal
, ranz2nix
}:
let
  src = next-terminal;

  noderanz = callPackage ranz2nix {

    nodejs = nodejs-12_x;
    sourcePath = src + "/web/";
    packageOverride = name: spec:
      if name == "minimist" && spec ? resolved && spec.resolved == "" then {
        resolved = "file://" + (
          toString (
            fetchurl {
              url = "https://registry.npmjs.org/minimist/-/minimist-1.2.0.tgz";
              sha256 = "0w7jll4vlqphxgk9qjbdjh3ni18lkrlfaqgsm7p14xl3f7ghn3gc";
            }
          )
        );
      } else { };
  };
  node_modules = noderanz.patchedBuild;
in
stdenv.mkDerivation {

  name = "next-terminal-static";

  inherit src;

  nativeBuildInputs = [ nodejs-12_x ];

  sourceRoot = "source/web";

  postUnpack = ''
    chmod -R +rw .
  '';

  NODE_ENV = "production";

  buildPhase = ''
    export HOME=$(mktemp -d)
    ln -sf ${node_modules}/node_modules node_modules
    ln -sf ${node_modules.lockFile} package-lock.json
    npm run build
  '';

  installPhase = ''
    cp -rv build $out
  '';
}
