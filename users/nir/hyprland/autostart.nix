# Autostart (was spawn.nix).
#
# Lua config has no `exec-once`; processes are started from the `hyprland.start`
# event. This is emitted verbatim into the generated `hyprland.lua` via
# `extraConfig`.
#
# Deliberately short: anything long-lived belongs in a systemd user unit so it
# gets restart-on-failure, journald logs and ordering against
# graphical-session.target. What used to be here and why it went:
#
#   mpd                  -> services.mpd was already enabled by users/nir/mpd.nix
#                           and mpd.service is active, so this spawned a second
#                           instance that could not bind its socket.
#   mpd-mpris            -> now services.mpd-mpris, which drops the
#                           "sleep 5 && mpd-mpris" race workaround.
#   kdeconnectd          -> NixOS programs.kdeconnect already D-Bus activates it.
#   transmission-daemon  -> users/nir/user-services.nix.
#   wl-paste --watch cliphist store (x2)
#                        -> `cliphist` is not installed anywhere (not in the
#                           system profile, user profile, or the nix store), so
#                           both watchers were dead. Neither noctalia nor
#                           vicinae reads cliphist; both keep their own clipboard
#                           store, and those are what Super+V / Super+CTRL+V use.
#
# noctalia is intentionally absent: Home Manager installs it as a user service
# with WantedBy=graphical-session.target, which Hyprland starts itself. Adding an
# exec_cmd here would launch a second shell.
{...}: {
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("trash-empty 30")
      hl.exec_cmd("hyprctl setcursor Bibata_Ghost 37")
    end)
  '';
}
