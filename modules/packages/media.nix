{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Subtitle / Japanese media tooling
    ffmpegthumbnailer
    python3Packages.guessit
    mecab
    anki

    # Video & image
    (mpv.override {
      scripts = with mpvScripts; [
        autoload
        autosub
        autosubsync-mpv
        memo
        mpris
        thumbfast
        uosc
      ];
    })
    ffmpeg
    kdePackages.kdenlive
    mediainfo
    yt-dlp
    ffsubsync
    (pkgs.callPackage ../../pkgs/alass {})
    imagemagick
    ghostscript

    # Files & archives
    yazi
    ouch
    unar
    unrar
    p7zip

    # Reading
    newsboat
    nsxiv
    readest
    epub-thumbnailer
    calibre
    zathura
    xournalpp
    typst
    pandoc

    # Audio
    cava
    pulsemixer
    mpd
    mpc
    ncmpcpp
    mpd-mpris
  ];
}
