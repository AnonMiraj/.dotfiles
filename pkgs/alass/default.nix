{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "alass";
  version = "2.0.0";

  src = fetchurl {
    url = "https://github.com/kaegi/alass/releases/download/v${version}/alass-linux64";
    hash = "sha256-e9C5rn4DXTupQOrP+yEkNhTfNiMdR/IfC0zkIAGrf80=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    install -Dm755 $src $out/bin/alass
  '';

  meta = with lib; {
    description = "Automatic Language-Agnostic Subtitle Synchronization";
    homepage = "https://github.com/kaegi/alass";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = [];
  };
}
