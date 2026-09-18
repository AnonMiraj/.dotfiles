{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Comms & browsers
    websocat
    telegram-desktop
    vesktop
    brave

    # Remote access / tunnels
    sshfs
    mkcert
    protonup-rs
    (pkgs.callPackage ../../pkgs/hiddify {})

    # Media casting
    scrcpy

    # Android / Samsung device tooling
    heimdall
    android-tools
    better-adb-sync
    (import ../../pkgs/odin4 {
      inherit (pkgs) lib stdenv fetchurl unzip autoPatchelfHook libusb1;
    })

    # Torrent client (GUI) + its curses remote
    transmission_4-gtk
    tremc
  ];
}
