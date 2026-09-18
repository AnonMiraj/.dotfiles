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
    xwayland-satellite
    inputs.niri-zoom.packages.${pkgs.stdenv.hostPlatform.system}.default
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
    inputs.stasis.packages.${pkgs.stdenv.hostPlatform.system}.stasis
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
