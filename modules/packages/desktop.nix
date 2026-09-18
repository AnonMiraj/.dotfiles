{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Graphics / GPU
    vulkan-tools
    mesa-demos
    xrandr
    xdotool
    xwininfo

    # Session integration
    libnotify
    xdg-desktop-portal-termfilechooser
    zenity
    trash-cli
    presenterm
    xxhash
    # Clipboard. wl-clipboard provides wl-copy/wl-paste, which nvim uses for
    # the `+` register on Wayland and which scripts (nsxiv, noctalia's
    # clipboardWatchTextCommand) shell out to; wtype is what noctalia uses to
    # synthesise the paste chord for clipboard auto-paste. Neither was
    # installed, which is why copying from a terminal worked but pasting the
    # entry back out of the clipboard panel did not.
    wl-clipboard
    wtype
    # Shells / bars / wallpaper
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default
    vicinae

    # Dictation
    hyprwhspr-rs
    whisper-cpp

    # Hardware control
    i2c-tools
    ddcutil

    # Cursors
    bibata-cursors-translucent
    bibata-cursors
  ];
}
