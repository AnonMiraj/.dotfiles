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

      # ── TheFarmerWasReplaced — floating ──────────────────
      {
        match.title = "^TheFarmerWasReplaced$";
        float = true;
      }

      # ── Settings apps ────────────────────────────────────
      {
        match.class = "^gnome-control-center$";
        scrolling_width = 0.5;
      }
      {
        match.class = "^pavucontrol$";
        scrolling_width = 0.5;
      }
      {
        match.class = "^nm-connection-editor$";
        scrolling_width = 0.5;
      }

      # ── xdg-desktop-portal — floating ────────────────────
      {
        match.class = "^xdg-desktop-portal$";
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

  # Static window rules are evaluated once, at map time, against the *initial*
  # class/title — so a rule keyed on a title the app sets later never fires.
  # That is exactly the case for Telegram's media viewer and Zen's
  # picture-in-picture window, so re-apply the float on the title event. This
  # is the pattern upstream documents for static rules that depend on a title
  # change.
  #
  # `action = "enable"` rather than toggle: the event can fire more than once
  # for the same window, and the intent is idempotent.
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("window.title", function(w)
      if w == nil then return end
      if w.title == "Media viewer" or w.title:match("^Picture%-in%-Picture$") then
        hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
      end
    end)
  '';
}
