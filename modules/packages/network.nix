{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Comms & browsers
    websocat
    telegram-desktop
    vesktop
    brave

    # Remote access / tunnels
    mkcert
    (pkgs.callPackage ../../pkgs/hiddify {})

    # Media casting
    scrcpy

    # Android tooling
    android-tools

    # Torrent client (curses remote for the transmission daemon)
    tremc
  ];
}
