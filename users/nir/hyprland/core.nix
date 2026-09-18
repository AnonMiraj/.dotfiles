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
        no_focus_fallback = true;
        gaps_workspaces = 50;
        allow_tearing = true;
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
        # Hyprland's default is true, so a lone column stretches across the
        # whole screen. niri never did that: niri `default-column-width` was
        # { proportion = 0.5; }, and a single column kept that width. It also
        # fought the per-app `scrolling_width` rules in rules.nix, which are
        # all ignored for a lone window while this is on.
        fullscreen_on_one_column = false;
      };

      # ── Decoration ───────────────────────────────────────
      decoration = {
        rounding = 12;
        rounding_power = 2.0;
        active_opacity = 0.89;
        inactive_opacity = 0.89;

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
        # Both layouts live here again, so they apply to every key event in every
        # application, games included. fcitx5 briefly owned them while it was
        # tried for per-window layout memory; it could only manage its own input
        # methods, which application that do not speak the input-method protocol
        # never see, and it turned out not to give per-window memory anyway - a
        # new window inherited whatever input method was active. Per-window
        # memory is the daemon in users/nir/user-services.nix instead, which
        # moves these XKB groups around.
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
        pass_mouse_when_bound = false;
        allow_workspace_cycles = true;
        # Swiping away from the scratchpad should hide it, like every other
        # scratchpad implementation. Hyprland's default leaves it showing.
        hide_special_on_workspace_change = true;
        # niri exits fullscreen when you move focus off a fullscreen window;
        # the default makes movefocus a no-op while fullscreen instead.
        movefocus_cycles_fullscreen = true;
      };

      # ── Cursor ───────────────────────────────────────────
      cursor = {
        no_hardware_cursors = 1;
        enable_hyprcursor = true;
        warp_on_change_workspace = 1;
      };

      # ── Misc ─────────────────────────────────────────────
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        # niri only enabled VRR on mpv, so fullscreen-only is the closest.
        vrr = 2;
        # Needed so the SUPER+SHIFT+P DPMS bind can be woken with a key press.
        key_press_enables_dpms = true;
        # Default is false, so an app requesting activation (a link clicked in
        # kitty, for example) is not raised. niri honoured those requests, so
        # this restores that behaviour.
        focus_on_activate = true;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
        mouse_move_enables_dpms = true;
        allow_session_lock_restore = true;
        initial_workspace_tracking = 0;
      };

      xwayland = {
        enabled = true;
      };
    };

    # ── Per-device: GameSir controller ─────────────────────
    # Sibling of `config`, not inside it: per-device settings are their own
    # hl.device({...}) calls, so putting this under config silently renders it
    # as unknown config keys instead.
    #
    # The GameSir dongle re-enumerates continuously: 1367 USB attach cycles in
    # one session, alternating between product IDs 3537:1094 and 3537:1093 on
    # usb 3-2 roughly every 5 seconds, with no USB errors logged. It presents
    # three interfaces each time (Joystick, Keyboard, Mouse).
    #
    # That is what made the numpad flip about between digits and navigation:
    #
    #   1. Every attach calls CInputManager::applyConfigToKeyboard, which runs
    #      IKeyboard::setKeymap(). Because input:numlock_by_default = true, that
    #      forces the NumLock XKB modifier LOCKED for that keyboard.
    #   2. shareModsFromAllKBs() ORs every *enabled* keyboard's modifiers into
    #      the session mask, so that forced bit reaches the real keyboard.
    #   3. On detach the bit goes away again, and the next attach re-adds it.
    #
    # So it was never about Super combos - that was just when it was noticed.
    #
    # Disabling the device removes it from step 2: shareModsFromAllKBs skips
    # keyboards with m_enabled == false, so the flapping can no longer disturb
    # the modifier state. Gamepad input is unaffected because games read
    # gamepads from evdev directly, not through the compositor. It also stops
    # the device reclaiming the `main` keyboard slot from the Ducky.
    #
    # This hides the symptom rather than the cause. The flapping itself is
    # device firmware - two alternating product IDs and no USB errors - so if
    # it still causes trouble, address it there (different port, powered hub,
    # disabled USB autosuspend for 3537:1094/3537:1093, or vendor firmware).
    #
    # If its keyboard mode is ever wanted, drop `enabled` and use
    # share_states = 0 instead, which stops the modifier state being merged with
    # the real keyboard without disabling the device.
    device = [
      {
        name = "gamesir-tegenaria-lite-keyboard";
        enabled = false;
      }
    ];

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

    # No `gesture` entries: this machine is driven by keyboard and mouse only.
    # Every trackpad and touch gesture was removed on request. Zoom is still
    # bound to CTRL + wheel in binds.nix, which works from a real mouse wheel.
  };
}
