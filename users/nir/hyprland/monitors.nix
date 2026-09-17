# Monitor layout + named workspace placement (was outputs.nix).
{...}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      {
        output = "eDP-1";
        mode = "1920x1080@144";
        scale = 1;
        position = "0x0";
      }
      {
        output = "HDMI-A-1";
        mode = "2560x1440@144";
        scale = 1;
        position = "1920x0";
      }
    ];
  };
}
