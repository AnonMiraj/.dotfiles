{
  config,
  pkgs,
  ...
}: {
  # X11
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  programs.xwayland.enable = true;

  # Sound (PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Desktop: Niri + Ly (TUI DM)
  services.desktopManager.cosmic.enable = true;
  services.displayManager.ly.enable = true;
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri;

  # Speech-to-text dictation
  services.hyprwhspr-rs.enable = true;

  # Ly TUI display manager config
  services.displayManager.ly.settings = {
    animation = "colormix";
    bigclock = "en";
    bigclock_12hr = false;
    bigclock_seconds = false;
    animation_frame_delay = 5;
    animation_timeout_sec = 30;
    # colormix color scheme
    colormix_col1 = "0x00FF0000";
    colormix_col2 = "0x0000FF00";
    colormix_col3 = "0x200000FF";
  };

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      xdg-desktop-portal-termfilechooser
      xdg-desktop-portal-wlr
    ];
    config.niri = {
      default = pkgs.lib.mkForce ["gtk" "gnome" "*"];
      "org.freedesktop.impl.portal.ScreenCast" = pkgs.lib.mkForce ["gnome"];
      "org.freedesktop.impl.portal.Screenshot" = pkgs.lib.mkForce ["gnome"];
      "org.freedesktop.impl.portal.FileChooser" = pkgs.lib.mkForce ["termfilechooser"];
    };
    config.common = {
      default = ["*"];
      "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
    };
  };
}
