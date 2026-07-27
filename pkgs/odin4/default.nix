{ lib, stdenv, fetchurl, unzip, autoPatchelfHook, libusb1 }:

stdenv.mkDerivation rec {
  pname = "odin4";
  version = "1.2.1";

  src = fetchurl {
    url = "https://github.com/Adrilaw/OdinV4/releases/download/v1.0/odin.zip";
    hash = "sha256-2RjxMrCy7ly+7yf7Yfau7jc0zbICstyOOEWpVTAwAsU=";
  };

  nativeBuildInputs = [ unzip autoPatchelfHook ];

  buildInputs = [ libusb1 ];

  sourceRoot = ".";

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    install -Dm755 odin4 $out/bin/odin4
  '';

  meta = with lib; {
    description = "Samsung Odin v4 for Linux — flash firmware to Samsung devices";
    homepage = "https://github.com/Adrilaw/OdinV4";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
