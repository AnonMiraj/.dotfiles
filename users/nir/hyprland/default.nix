{
  imports = [
    ./core.nix
    ./monitors.nix
    ./binds.nix
    ./rules.nix
    ./animations.nix
    ./autostart.nix
    ./hyprsplit.nix
    ./scrolloverview.nix
    ./scripts.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    # Hyprland 0.55 deprecated the hyprlang `.conf` format in favour of Lua.
    # `configType = "lua"` writes ~/.config/hypr/hyprland.lua and renders
    # `settings` attributes as `hl.<name>(...)` calls.
    configType = "lua";
    # Required on Hyprland 0.56.2. The wiki says session targets are now
    # handled automatically, but that is `main`-only: the 0.56.2 binary only
    # knows HYPRLAND_NO_SD_NOTIFY / NO_SD_VARS, never starts
    # graphical-session.target. Without this, noctalia / vicinae /
    # jellyfin-mpv-shim never start (their WantedBy target stays inactive) and
    # you get an empty desktop with no bar.
    #
    # This installs hyprland-session.target (BindsTo=graphical-session.target)
    # and emits `systemctl --user start hyprland-session.target`; the BindsTo
    # pulls graphical-session.target in as a dependency, which
    # RefuseManualStart=yes otherwise blocks from a direct `systemctl start`.
    systemd.enable = true;
  };
}
