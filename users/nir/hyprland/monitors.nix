# Monitor layout + named workspace placement (was outputs.nix).
{...}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      {
        output = "HDMI-A-1";
        mode = "2560x1440@144";
        scale = 1;
        position = "0x0";
      }
      {
        output = "eDP-1";
        mode = "1920x1080@144";
        scale = 1;
        position = "2560x0";
      }
    ];

    # No workspace_rule entries here any more: workspace-to-monitor assignment
    # belongs to hyprsplit (see hyprsplit.nix). It reserves underlying ids 1-10
    # for eDP-1 and 11-20 for HDMI-A-1, so the old named browser/chat
    # workspaces became plain 1 and 2 on eDP-1.
  };
}
