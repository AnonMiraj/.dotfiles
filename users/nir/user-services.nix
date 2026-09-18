# Long-lived session daemons as systemd user units.
#
# These were started from the compositor's startup hook as bare `exec_cmd`
# children. As units they get restart-on-failure, journald logs, and real
# ordering against graphical-session.target.
{pkgs, ...}: {
  systemd.user.services.transmission-daemon = {
    Unit = {
      Description = "Transmission BitTorrent daemon";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      # %h is the systemd user-unit specifier for the home directory; the old
      # exec_cmd relied on shell tilde expansion instead.
      # --foreground keeps the daemon as the unit's main process (systemd does
      # the supervising) rather than letting it fork away.
      ExecStart = "${pkgs.transmission_4-gtk}/bin/transmission-daemon --foreground";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = ["graphical-session.target"];
  };

  # Each window remembers its own keyboard layout, which is what niri's
  # `track-layout "window"` did. Hyprland has nothing built in for this: the
  # kb_* fields on hl.device are per-device rather than per-window, and
  # `hyprctl switchxkblayout` only switches on demand. This daemon listens on
  # Hyprland's socket2 for activewindow events and moves the XKB groups to
  # match the window that gained focus.
  #
  # Because it drives XKB groups rather than an input method, the layouts reach
  # every application that gets key events, which is what fcitx5 could not do.
  #
  # It reads HYPRLAND_INSTANCE_SIGNATURE (and XDG_RUNTIME_DIR) to find the
  # socket; Hyprland's session integration already puts both in the systemd user
  # manager's environment, so nothing has to be passed here.
  systemd.user.services.hyprland-per-window-layout = {
    Unit = {
      Description = "Per-window keyboard layout for Hyprland";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${pkgs.hyprland-per-window-layout}/bin/hyprland-per-window-layout";
      # Reaching graphical-session.target does not guarantee that .socket2.sock
      # exists yet, and the daemon exits when it cannot connect, so let systemd
      # retry rather than failing for the whole session.
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = ["graphical-session.target"];
  };
}
