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
  patchedPackageLockFile = runCommand "patch"
    {
      inherit src;
    }
    ''
      cp -r $src/web/package-lock.json .
      chmod -R +rw package-lock.json
      sed -i 's|https://registry.npm.taobao.org/dayjs/download/dayjs-1.10.4.tgz?cache=0&sync_timestamp=1611309982734&other_urls=https%3A%2F%2Fregistry.npm.taobao.org%2Fdayjs%2Fdownload%2Fdayjs-1.10.4.tgz|https://registry.npm.taobao.org/dayjs/download/dayjs-1.10.4.tgz|' package-lock.json
      cp package-lock.json $out
    '';

  noderanz = callPackage ranz2nix {

    nodejs = nodejs-12_x;
    sourcePath = src + "/web/";
    lockFilePath = patchedPackageLockFile;
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
