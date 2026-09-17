# Autostart (was spawn.nix).
#
{...}: {
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("trash-empty 30")
    end)
  '';
}
