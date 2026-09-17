# Compositor settings, environment and input.
#
# Home Manager renders `settings = { config = ... }` as `hl.config({ ... })` in
# the generated `~/.config/hypr/hyprland.lua` because `configType = "lua"`.
# Structured Nix values become Lua tables, `_args` lists become multi-argument
# `hl.<name>(...)` calls.
{...}: {
  wayland.windowManager.hyprland.settings = {
    config = {
      # ── General / layout ─────────────────────────────────
      general = {
        # Closest thing to niri: columns on an infinite tape.
        layout = "scrolling";
        gaps_in = 4;
        gaps_out = 4;
        # niri had border disabled + a 2px focus ring; Hyprland only has
        # borders, so the border carries the focus-ring look.
        border_size = 2;
        resize_on_border = true;
        col = {
          active_border = "#707070ff";
          inactive_border = "#d0d0d0ff";
        };
      };

      # ── Scrolling layout ─────────────────────────────────
      scrolling = {
        column_width = 0.5;
        explicit_column_widths = "0.333,0.5,0.667";
        # niri `center-focused-column = "never"`.
        focus_fit_method = 1;
        follow_focus = true;
        fullscreen_on_one_column = true;
      };

      # ── Decoration ───────────────────────────────────────
      decoration = {
        rounding = 12;
        rounding_power = 2.0;
        # niri window rule `opacity = 0.95` applied globally.
        active_opacity = 0.95;
        inactive_opacity = 0.95;

        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          # niri blur.noise = 0.05
          noise = 0.05;
          # niri blur.saturation = 3, clamped to Hyprland's 0.0 - 1.0 range.
          vibrancy = 0.3;
          new_optimizations = true;
          # niri background-effect.xray = true
          xray = true;
          popups = true;
        };

        shadow = {
          enabled = true;
          # niri softness = 30, spread = 5, offset = { 0, 5 }
          range = 30;
          render_power = 3;
          # vec2: must be a 2-element list, not an { x; y; } attrset.
          offset = [
            0
            5
          ];
          color = "#00000070";
        };
      };

      # ── Input ────────────────────────────────────────────
      input = {
        kb_layout = "us,ara";
        # grp:win_space_toggle cycles the groups; SUPER + space is free for it
        # again now that fcitx5 no longer claims that key.
        kb_options = "grp:win_space_toggle,caps:escape,altwin:menu_win";
        repeat_delay = 255;
        repeat_rate = 40;
        numlock_by_default = true;
        # niri focus-follows-mouse.enable = true
        follow_mouse = 1;

        touchpad = {
          tap_to_click = true;
          natural_scroll = true;
        };
      };

      # ── Binds ────────────────────────────────────────────
      binds = {
        # niri workspace-auto-back-and-forth = true
        workspace_back_and_forth = true;
        # niri used cooldown-ms = 150 on wheel binds.
        scroll_event_delay = 150;
      };

      # ── Misc ─────────────────────────────────────────────
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        # niri only enabled VRR on mpv, so fullscreen-only is the closest.
        vrr = 2;
        # Default is false, so an app requesting activation (a link clicked in
        # kitty, for example) is not raised. niri honoured those requests, so
        # this restores that behaviour.
        focus_on_activate = true;
      };

      xwayland = {
        enabled = true;
      };

      binds = {
        # Swiping away from the scratchpad should hide it, like every other
        # scratchpad implementation. Hyprland's default leaves it showing.
        hide_special_on_workspace_change = true;
        # niri exits fullscreen when you move focus off a fullscreen window;
        # the default makes movefocus a no-op while fullscreen instead.
        movefocus_cycles_fullscreen = true;
      };
    };

    # ── Environment ────────────────────────────────────────
    # `settings.env` entries become `hl.env(name, value)`.
    env = [
      {_args = ["QT_QPA_PLATFORM" "wayland;xcb"];}
      {_args = ["QT_QPA_PLATFORMTHEME" "gtk3"];}
      {_args = ["QT_QPA_PLATFORMTHEME_QT6" "gtk3"];}
      {_args = ["ELECTRON_OZONE_PLATFORM_HINT" "auto"];}
      {_args = ["NIXOS_OZONE_WL" "1"];}
      {_args = ["XCURSOR_THEME" "Bibata_Ghost"];}
      {_args = ["XCURSOR_SIZE" "37"];}
    ];
  };
}
