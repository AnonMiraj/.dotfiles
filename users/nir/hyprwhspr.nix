# Supplies the tray script the Noctalia widget (goodroot/noctwhspr) polls.
#
# The widget resolves its script as `<root>/config/hyprland/hyprwhspr-tray.sh`,
# trying its own `root` setting, then HYPRWHSPR_ROOT from Noctalia's environment,
# then /usr/lib/hyprwhspr. It then shells out with one of three actions and
# parses the reply with plain Lua string patterns:
#
#   status  -> '"class":"<state>"' and '"tooltip":"<text>"'
#   record  -> left click, toggles recording
#   restart -> right click, restarts the service
#
# `class` must be one of recording, ready, unloaded, stopped or error; anything
# else is rendered as error. Upstream ships that script inside the Python
# implementation, which this host does not run. hyprwhspr-rs is used instead
# because it is a single nixpkgs binary, and it provides everything the widget
# needs through `hyprwhspr-rs record` - it never touches /dev/input itself (no
# evdev, grab or /dev/input references in the binary), so the compositor bind is
# its only hotkey path and there is nothing to double-fire.
#
# So this is the shim that keeps the widget working on top of hyprwhspr-rs.
# It is deliberately small: it reports state from the daemon and forwards the
# two clicks.
{
  pkgs,
  config,
  ...
}: let
  trayShim = pkgs.writeShellScript "hyprwhspr-rs-tray" ''
    set -u

    # The widget looks for "class" and "tooltip". Embedded newlines are written
    # as \n escapes so the reply stays valid JSON and single-line, which is what
    # the widget's patterns expect.
    emit() {
      printf '{"text":"","class":"%s","tooltip":"%s\\n_ts:%s"}\n' \
        "$1" "$2" "$(date +%s%3N 2>/dev/null || printf 0)"
    }

    service_active() {
      systemctl --user is-active --quiet hyprwhspr-rs.service
    }

    case "''${1:-status}" in
      status)
        if ! service_active; then
          emit stopped 'hyprwhspr-rs: service not running\nLeft-click: start recording\nRight-click: restart service'
          exit 0
        fi
        # `record status` prints the daemon's own view of the recorder.
        if ! out="$(hyprwhspr-rs record status 2>&1)"; then
          emit error "hyprwhspr-rs: status query failed\n$out"
          exit 0
        fi
        # `record status` prints a bare state word: "inactive" when idle. Note
        # that "inactive" contains "active", so the recording test has to be for
        # the word itself rather than a substring of the generic one.
        case "$out" in
          *[Rr]ecording*) emit recording "hyprwhspr-rs: Recording\nLeft-click: stop\nRight-click: restart service" ;;
          inactive|idle|"") emit ready "hyprwhspr-rs: Ready\nLeft-click: start recording\nRight-click: restart service" ;;
          # Anything unexpected is surfaced rather than hidden.
          *) emit ready "hyprwhspr-rs: Ready ($out)\nLeft-click: start recording\nRight-click: restart service" ;;
        esac
        ;;

      record|toggle)
        if ! service_active; then
          systemctl --user start hyprwhspr-rs.service
        fi
        hyprwhspr-rs record toggle
        ;;

      start) hyprwhspr-rs record start ;;
      stop) hyprwhspr-rs record stop ;;

      restart)
        systemctl --user restart hyprwhspr-rs.service
        ;;

      health)
        service_active && printf 'ok\n' || printf 'down\n'
        ;;

      *)
        printf 'usage: %s [status|record|toggle|start|stop|restart|health]\n' "$0" >&2
        exit 2
        ;;
    esac
  '';

  # Root the widget searches. It is not an install prefix for anything real -
  # only the shim lives under it.
  root = "${config.xdg.configHome}/hyprwhspr-shim";
in {
  xdg.configFile."hyprwhspr-shim/config/hyprland/hyprwhspr-tray.sh".source = trayShim;

  # The widget reads HYPRWHSPR_ROOT from Noctalia's environment (see the
  # candidate order in its widget.luau), and Noctalia is a systemd user service.
  systemd.user.sessionVariables.HYPRWHSPR_ROOT = root;
  # environment.d is only read when the systemd user manager starts, so a rebuild
  # would not reach a running Noctalia until the next login. Setting it on the
  # unit as well makes the current session pick it up immediately.
  systemd.user.services.noctalia.Service.Environment = ["HYPRWHSPR_ROOT=${root}"];
}
