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

    # Overview keybinds + the plugin's dynamic-workspaces recipe.
    # The submap has to be declared for the plugin to enter one at all, and
    # declaring it replaces the built-in navigation, so the documented binds are
    # repeated below. See docs/wiki/{Keybind-submap,Dynamic-workspaces}.md.
    extraLuaFiles."scrolloverview-overview" = ''
      local lastWorkspaceScrollBind

      local function table_value(value, ...)
        if value == nil then
          return nil
        end
        for _, key in ipairs({ ... }) do
          local ok, item = pcall(function()
            return value[key]
          end)
          if ok and item ~= nil then
            return item
          end
        end
        return nil
      end

      local function last_workspace_state()
        local monitor = hl.get_monitor_at_cursor() or hl.get_active_monitor()
        if not monitor then
          return false, nil
        end

        local activeWorkspace = table_value(monitor, "active_workspace")
        local activeWorkspaceId = table_value(activeWorkspace, "id")
        if type(activeWorkspaceId) ~= "number" or activeWorkspaceId <= 0 then
          return false, nil
        end

        local activeWorkspaceWindows = table_value(activeWorkspace, "windows")
        if type(activeWorkspaceWindows) ~= "number" or activeWorkspaceWindows == 0 then
          return false, nil
        end

        local lastWorkspaceId
        for _, workspace in ipairs(hl.get_workspaces()) do
          local id = table_value(workspace, "id")
          if
            type(id) == "number"
            and id > 0
            and table_value(workspace, "special") ~= true
            and table_value(workspace, "monitor") == monitor
          then
            lastWorkspaceId = math.max(lastWorkspaceId or id, id)
          end
        end

        return activeWorkspaceId == lastWorkspaceId, monitor
      end

      local function create_workspace_at_end()
        local isLastWorkspace, monitor = last_workspace_state()
        if not isLastWorkspace or not monitor then
          return
        end

        hl.dispatch(hl.dsp.focus({ monitor = table_value(monitor, "name") }))
        hl.dispatch(hl.dsp.focus({ workspace = "emptynm" }))
      end

      local function update_last_workspace_scroll_bind()
        if not lastWorkspaceScrollBind then
          return
        end

        local enabled = false
        if hl.get_current_submap() == "scrolloverview" then
          enabled = last_workspace_state()
        end

        lastWorkspaceScrollBind:set_enabled(enabled)
      end

      hl.define_submap("scrolloverview", function()
        hl.bind("left", hl.plugin.scrolloverview.navigate("left"))
        hl.bind("right", hl.plugin.scrolloverview.navigate("right"))
        hl.bind("up", hl.plugin.scrolloverview.navigate("up"))
        hl.bind("down", hl.plugin.scrolloverview.navigate("down"))
        hl.bind("return", hl.plugin.scrolloverview.overview("select"))
        hl.bind("escape", hl.plugin.scrolloverview.overview("off"))
        hl.bind("mouse:272", function()
          hl.plugin.scrolloverview.overview("select")
          hl.plugin.scrolloverview.window("select")
          hl.plugin.scrolloverview.overview("off")
        end, { mouse = true })
        hl.bind("mouse:274", hl.plugin.scrolloverview.window("close"), { mouse = true })

        lastWorkspaceScrollBind = hl.bind("mouse_down", create_workspace_at_end)
        lastWorkspaceScrollBind:set_enabled(false)

        -- SUPER + wheel moves to the next/previous workspace, matching the
        -- global SUPER + wheel binds outside the overview. Past the last
        -- workspace it creates a new one (same as the bare mouse_down bind).
        hl.bind("SUPER + mouse_down", function()
          if last_workspace_state() then
            create_workspace_at_end()
            return
          end
          ws_cycle(1)
        end, { auto_consuming = true })
        hl.bind("SUPER + mouse_up", function()
          ws_cycle(-1)
        end, { auto_consuming = true })
      end)

      hl.on("workspace.active", update_last_workspace_scroll_bind)
      hl.on("workspace.created", update_last_workspace_scroll_bind)
      hl.on("workspace.removed", update_last_workspace_scroll_bind)
      hl.on("workspace.move_to_monitor", update_last_workspace_scroll_bind)
      hl.on("window.open", update_last_workspace_scroll_bind)
      hl.on("window.close", update_last_workspace_scroll_bind)
      hl.on("window.move_to_workspace", update_last_workspace_scroll_bind)
      hl.on("monitor.focused", update_last_workspace_scroll_bind)
      hl.on("keybinds.submap", update_last_workspace_scroll_bind)

      hl.timer(update_last_workspace_scroll_bind, {
        timeout = 50,
        type = "repeat",
      })

      update_last_workspace_scroll_bind()
    '';
  };
}
