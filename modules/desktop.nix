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

  # Sound (PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Desktop: Hyprland (primary) + COSMIC (backup) + Ly (TUI DM).
  #
  # Each of them brings its own XWayland (programs.hyprland.xwayland
  # and services.desktopManager.cosmic.xwayland both default to true), so
  # programs.xwayland is not needed here.
  services.desktopManager.cosmic.enable = true;
  services.displayManager.ly.enable = true;

  programs.hyprland = {
    enable = true;
    # No UWSM: Hyprland >= 0.5x starts hyprland-session.target and
    # graphical-session.target natively, and the wiki now says to drop
    # manual systemctl target juggling. noctalia (WantedBy=
    # graphical-session.target) therefore starts on its own.
  };

  # Speech-to-text dictation, via hyprwhspr-rs (a single nixpkgs binary). The
  # Noctalia bar widget goodroot/noctwhspr is kept working on top of it by the
  # tray-script shim in users/nir/hyprwhspr.nix; upstream only ships that script
  # inside the heavier Python implementation, which this host does not run.
  #
  # hyprwhspr-rs never reads /dev/input, so unlike the Python implementation it
  # has no hotkey of its own - the compositor binding in
  # users/nir/hyprland/binds.nix is the only thing that starts a recording.
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
  # Hyprland ships its own portal, so xdg-desktop-portal-wlr is not needed
  # (the NixOS module also sets enableWlrPortal = false).
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      xdg-desktop-portal-termfilechooser
    ];
    config.hyprland = {
      default = pkgs.lib.mkForce ["gtk" "hyprland" "*"];
      "org.freedesktop.impl.portal.ScreenCast" = pkgs.lib.mkForce ["hyprland"];
      "org.freedesktop.impl.portal.Screenshot" = pkgs.lib.mkForce ["hyprland"];
      "org.freedesktop.impl.portal.FileChooser" = pkgs.lib.mkForce ["termfilechooser"];
    };
    config.common = {
      default = ["*"];
      "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
    };
  };
}
