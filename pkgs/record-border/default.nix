{ stdenv, pkg-config, gtk3, gtk-layer-shell, cairo }:

stdenv.mkDerivation {
  pname = "record-border";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ gtk3 gtk-layer-shell cairo ];

  buildPhase = ''
    $CC -O3 -Wall $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0 cairo) main.c -o record-border
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp record-border $out/bin/
  '';
}
