# Scrollable overview (niri-style) via the hyprland-scroll-overview plugin.
#
# Chosen over hyprshell (rejected) and hyprexpo (dead upstream at v0.54.0).
# This is a real plugin, so Hyprland's PLUGIN_API_VERSION check applies: it is
# built from source against this repo's pkgs.hyprland (0.56.2), the same version
# the session runs, which is what makes the API handshake line up.
#
# Loaded via the `plugins` option, which Home Manager renders as
# hl.plugin.load("<pkg>/lib/lib<pname>.so"), so the package must be named
# scrolloverview and install libscrolloverview.so.
#
# The config must go through `settings.config.plugin.*` so it renders as
# `hl.config({ plugin = { scrolloverview = {...} } })`, matching upstream's Lua
# docs. Using `settings.plugin` instead renders `hl.plugin({...})`, and
# `hl.plugin` is a *table*, not a function — Hyprland then dies with
# "attempt to call a table value (field 'plugin')".
#
# Option names were checked against the plugin's Config.cpp registrations
# (plugin:scrolloverview:*) rather than the README, so none are unknown keys.
# Values follow upstream's documented starting point and are cheap to tune.
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
      # No gesture_distance: it only feeds CScrollOverview::onSwipeUpdate, which
      # needs a touchpad swipe to reach. The overview is bound to SUPER + Tab.

      shadow = {
        enabled = true;
        range = 50;
      };
    };
  };
}
