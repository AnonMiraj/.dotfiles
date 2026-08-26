{
  lib,
  appimageTools,
  fetchurl,
}: let
  pname = "hiddify";
  version = "4.1.1";
  src = fetchurl {
    url = "https://github.com/hiddify/hiddify-app/releases/download/v${version}/Hiddify-Linux-x64-AppImage.AppImage";
    hash = "sha256-6yu2wIlxuY4tCgH8W2R+KboXsWYRScyfl+2g53v1vcM=";
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs:
      with pkgs; [
        # Compression & Networking
        zstd
        brotli
        zlib
        curl
        openssl
        gnutls
        libssh
        libpsl
        libidn2
        libunistring
        openldap
        cyrus_sasl
        libkrb5
        keyutils
        p11-kit
        libtasn1
        nettle
        gmp
        nghttp2

        # GUI, Fonts & Desktop
        libepoxy
        gtk3
        glib
        gdk-pixbuf
        cairo
        pango
        atk
        at-spi2-atk
        at-spi2-core
        libxkbcommon
        wayland
        libGL
        libsecret
        json-glib
        fontconfig
        harfbuzz
        libayatana-appindicator
        ayatana-ido
        libdbusmenu-gtk3

        # X11
        libX11
        libXcursor
        libXrandr
        libXi
        libXcomposite
        libXdamage
        libXfixes
        libXrender
        libXtst
        libxcb

        # System
        systemd
      ];

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/hiddify.desktop $out/share/applications/hiddify.desktop 2>/dev/null || true
      install -m 444 -D ${appimageContents}/hiddify.png $out/share/icons/hicolor/512x512/apps/hiddify.png 2>/dev/null || true
      substituteInPlace $out/share/applications/hiddify.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=hiddify' 2>/dev/null || true
    '';

    meta = with lib; {
      description = "Multi-platform auto-proxy client, supporting Sing-box, Xray, Reality, VLESS, TUIC, Hysteria";
      homepage = "https://hiddify.com";
      license = licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      mainProgram = "hiddify";
    };
  }
