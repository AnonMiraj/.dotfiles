# Window rules + layer rules (was windowrules.nix).
#
# Hyprland matches on the *initial* class/title for static rules, so rules that
# relied on a title set after the window maps need the event-hook approach.
{...}: {
  wayland.windowManager.hyprland.settings = {
    window_rule = [
      {
        match.class = ".*";
        opacity = "0.89 override 0.89 override";
      }
      {
        match.xwayland = true;
        no_blur = true;
      }
      {
        match.float = false;
        no_shadow = true;
      }
      {
        match.class = "^zen-beta$";
        suppress_event = "maximize";
      }
      {
        match.class = ".*";
        idle_inhibit = "fullscreen";
      }
      {
        match.title = ".*\\.exe";
        immediate = true;
      }
      {
        match.class = "^steam_app";
        immediate = true;
      }
      {
        match.class = "^(blueberry\\.py|guifetch|steam)$";
        float = true;
      }
      {
        match.class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor)$";
        float = true;
        center = true;
        size = [
          "monitor_w * 0.45"
          "monitor_h * 0.45"
        ];
      }
      {
        match.title = "^([Oo]pen [Ff]ile|[Ss]elect a [Ff]ile|[Cc]hoose wallpaper|[Oo]pen [Ff]older|[Ss]ave [Aa]s|[Ll]ibrary|[Ff]ile [Uu]pload)(.*)$";
        float = true;
        center = true;
      }
      {
        match.title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$";
        float = true;
        keep_aspect_ratio = true;
        pin = true;
        size = [
          "monitor_w * 0.25"
          "monitor_h * 0.28"
        ];
        move = [
          "monitor_w * 0.73"
          "monitor_h * 0.72"
        ];
      }
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

      # ── Global opacity is 0.89, these stay fully opaque ──
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
        # # browser is workspace 1 of eDP-1 (underlying id 1 under hyprsplit).
        # workspace = "1";
        maximize = true;
        scrolling_width = 0.5;
      }
      {
        match = {
          class = "^zen-beta$";
          title = "^Picture-in-Picture$";
        };
        float = true;
        maximize = false;
      }
    ];

    # Scratchpad gets an extra outer gap.
    workspace_rule = [
      {
        workspace = "special:scratchpad";
        gaps_out = 30;
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

      {
        match.namespace = ".*";
        xray = true;
      }

      {
        match.namespace = "^(walker|selection|overview|anyrun|hyprpicker|indicator.*|osk|noanim)$";
        no_anim = true;
      }
    ];
  };

  # Re-apply float/pin when the title lands after the window mapped.
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
