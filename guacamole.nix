{ stdenv
, fetchFromGitHub
, autoreconfHook
, cairo
, libjpeg_turbo
, libpng
, libossp_uuid
, freerdp
, freerdpUnstable
, pango
, libssh2
, libvncserver
, libpulseaudio
, openssl
, libvorbis
, libwebp
, pkgconfig
, perl
, libtelnet
, inetutils
, makeWrapper
}:

stdenv.mkDerivation rec {
  name = "guacamole-${version}";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "guacamole-server";
    rev = "90e15cb70635e8d13ebdefec9262701d2179983a";
    sha256 = "sha256-fUkWn+NPfWEr35Yrt+OBf3/baz1xYdpWVise336RrJo=";
  };
  NIX_CFLAGS_COMPILE = [
    "-Wno-error=format-truncation"
    "-Wno-error=format-overflow"
  ];

  buildInputs = with stdenv; [ freerdp freerdpUnstable autoreconfHook pkgconfig cairo libpng libjpeg_turbo libossp_uuid pango libssh2 libvncserver libpulseaudio openssl libvorbis libwebp libtelnet perl makeWrapper ];

  propogatedBuildInputs = with stdenv; [ freerdp autoreconfHook pkgconfig cairo libpng libjpeg_turbo libossp_uuid freerdp pango libssh2 libvncserver libpulseaudio openssl libvorbis libwebp inetutils ];

  patchPhase = ''
    substituteInPlace ./src/protocols/rdp/keymaps/generate.pl --replace "/usr/bin/env perl" "${perl}/bin/perl"
    substituteInPlace ./src/protocols/rdp/plugins/generate-entry-wrappers.pl --replace "/usr/bin/env perl" "${perl}/bin/perl"
    substituteInPlace ./src/protocols/rdp/Makefile.am --replace "-Werror -Wall" "-Wall"
    substituteInPlace ./src/protocols/rdp/Makefile.am --replace "@FREERDP2_PLUGIN_DIR@" "$out/lib"
  '';

  postInstall = ''
    wrapProgram $out/sbin/guacd --prefix LD_LIBRARY_PATH ":" $out/lib
  '';

  meta = with stdenv.lib; {
    description = "Clientless remote desktop gateway";
    homepage = "https://guacamole.incubator.apache.org/";
    maintainers = [ tomberek gtrunsec ];
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
