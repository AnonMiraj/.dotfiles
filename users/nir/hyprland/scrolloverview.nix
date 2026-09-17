# Scrollable overview (niri-style) via the hyprland-scroll-overview plugin.
#
# Config goes through settings.config.plugin.* so it renders as
# hl.config({ plugin = { scrolloverview = {...} } }); settings.plugin would
# render hl.plugin({...}) and hl.plugin is a table, not a function.
{pkgs, ...}: let
  scrolloverview = import ../../../pkgs/scrolloverview {
    inherit (pkgs) lib fetchFromGitHub lua5_4;
    inherit (pkgs.hyprlandPlugins) mkHyprlandPlugin;
  };
in {
  wayland.windowManager.hyprland = {
    plugins = [scrolloverview];

    # `settings.config` merges with core.nix's block, so this lands in the same
    # hl.config() call.
    settings.config.plugin.scrolloverview = {
      # 0.1 - 0.9, plugin default 0.5
      scale = 0.5;
      layout = "vertical";
      workspace_gap = 100;
      # 0 = global wallpaper only, 1 = per-workspace only, 2 = both
      wallpaper = 2;
      blur = true;

      shadow = {
        enabled = true;
        range = 50;
      };
    };
  };
}
