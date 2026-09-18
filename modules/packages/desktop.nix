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
