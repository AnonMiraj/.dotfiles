# Window rules + layer rules (was windowrules.nix).
#
# Hyprland matches on the *initial* class/title for static rules, so rules that
# relied on a title set after the window maps need the event-hook approach.
{...}: {
  wayland.windowManager.hyprland.settings = {
    window_rule = [
      # ── Telegram ─────────────────────────────────────────
      {
        match.class = "^org\\.telegram\\.desktop$";
        rounding = 6;
        # chat is workspace 2 of eDP-1 (underlying id 2 under hyprsplit).
        workspace = "2";
      }
      {
        match = {
          class = "^org\\.telegram\\.desktop$";
          title = "^Media viewer$";
        };
        float = true;
      }

      # ── Vesktop / Discord ────────────────────────────────
      {
        match.class = "^vesktop$";
        workspace = "2";
        scrolling_width = 0.66667;
      }
      {
        match.class = "^com\\.discordapp\\.Discord$";
        scrolling_width = 0.66667;
      }

      # ── Obsidian ─────────────────────────────────────────
      # niri used a fixed 1000px column; Hyprland scrolling_width is relative.
      {
        match.class = "^obsidian$";
        scrolling_width = 0.5;
      }

      # ── nvim — wider column ──────────────────────────────
      {
        match.title = "^nvim.*";
        scrolling_width = 0.66667;
      }

      {
        match.class = "^pavucontrol$";
        scrolling_width = 0.5;
      }
      {
        match.class = "^nm-connection-editor$";
        scrolling_width = 0.5;
      }

      # ── Screen-share picker — floating ───────────────────
      # This dialog has an empty class, so only the title identifies it.
      {
        match.title = "^Select what to share$";
        float = true;
      }

      # ── Global opacity is 0.95, these stay fully opaque ──
      {
        match.class = "^kitty$";
        opacity = "1.0 override 1.0 override 1.0 override";
      }
      {
        match.class = "^mpv$";
        monitor = "HDMI-A-1";
        opacity = "1.0 override 1.0 override 1.0 override";
      }

      # ── Noctalia settings window ─────────────────────────
      {
        match.class = "dev.noctalia.Noctalia";
        float = true;
        size = [1080 920];
      }

      # ── File chooser — floating, sized ───────────────────
      {
        match.class = "^file_chooser$";
        float = true;
        size = [
          "monitor_w * 0.6"
          "monitor_h * 0.6"
        ];
        move = [
          "monitor_w * 0.2"
          "monitor_h * 0.2"
        ];
      }

      # ── Zen browser — browser workspace, maximized ───────
      {
        match.class = "^zen-beta$";
        # browser is workspace 1 of eDP-1 (underlying id 1 under hyprsplit).
        workspace = "1";
        maximize = true;
        scrolling_width = 0.5;
      }
      {
        match = {
          class = "^zen-beta$";
          title = "^Picture-in-Picture$";
        };
        float = true;
        # Sticky: stays on screen across workspaces rather than scrolling away
        # with the tape, and pinned keeps a fixed size.
        pin = true;
        size = [540 304];
      }
    ];

    layer_rule = [
      # Noctalia's own recommended rule: blur its surfaces and keep Hyprland
      # from fighting its animations. Replaces niri's quickshell
      # place-within-backdrop rule.
      {
        name = "noctalia";
        match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$";
        no_anim = true;
        ignore_alpha = 0.5;
        blur = true;
        blur_popups = true;
      }

      # vicinae runs with layer_shell enabled at 0.98 opacity but had no rule
      # of its own, so nothing blurred behind the launcher. Namespace read from
      # `hyprctl layers` with the launcher open.
      {
        name = "vicinae";
        match.namespace = "^vicinae$";
        ignore_alpha = 0.5;
        blur = true;
        blur_popups = true;
      }
    ];
  };

  # Static rules are evaluated at map time, so a window that only acquires its
  # title later needs the float re-applied on the title event.
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("window.title", function(w)
      if w == nil then return end
      if w.title == "Media viewer" then
        hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
      elseif w.title:match("^Picture%-in%-Picture$") then
        hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
        hl.dispatch(hl.dsp.window.pin({ window = w, action = "enable" }))
      end
    end)
  '';
}
