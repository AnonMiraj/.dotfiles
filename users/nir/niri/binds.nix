{...}: {
  programs.niri.settings.binds = {
    # ── Media keys ─────────────────────────────────────────
    "XF86AudioRaiseVolume" = {
      action.spawn = ["noctalia" "msg" "volume-up" "3"];
      allow-when-locked = true;
    };
    "XF86AudioLowerVolume" = {
      action.spawn = ["noctalia" "msg" "volume-down" "3"];
      allow-when-locked = true;
    };
    "XF86AudioMute" = {
      action.spawn = ["noctalia" "msg" "volume-mute"];
      allow-when-locked = true;
    };
    "XF86AudioMicMute" = {
      action.spawn = ["noctalia" "msg" "mic-mute"];
      allow-when-locked = true;
    };
    "XF86MonBrightnessUp" = {
      action.spawn = ["noctalia" "msg" "brightness-up" "current" "5"];
      allow-when-locked = true;
    };
    "XF86MonBrightnessDown" = {
      action.spawn = ["noctalia" "msg" "brightness-down" "current" "5"];
      allow-when-locked = true;
    };
    "XF86AudioPlay" = {
      action.spawn = ["noctalia" "msg" "media" "toggle"];
      repeat = false;
    };
    "XF86AudioPause" = {
      action.spawn = ["noctalia" "msg" "media" "toggle"];
      repeat = false;
    };
    "XF86AudioNext" = {
      action.spawn = ["noctalia" "msg" "media" "next"];
      repeat = false;
    };
    "XF86AudioPrev" = {
      action.spawn = ["noctalia" "msg" "media" "previous"];
      repeat = false;
    };
    "XF86AudioStop" = {
      action.spawn = ["noctalia" "msg" "media" "stop"];
      repeat = false;
    };

    # ── Clipboard & tools ──────────────────────────────────
    "Mod+V" = {
      action.spawn = ["vicinae" "vicinae://launch/clipboard/history"];
      repeat = false;
    };
    "Mod+Ctrl+N" = {
      action.spawn = ["noctalia" "msg" "panel-toggle" "control-center"];
      repeat = false;
    };
    "Mod+Alt+L" = {
      action.spawn = ["noctalia" "msg" "session" "lock"];
      repeat = false;
    };

    # ── Window management ──────────────────────────────────
    "Super+F".action.maximize-column = [];
    "Super+Shift+F".action.fullscreen-window = [];
    "Super+S".action.toggle-window-floating = [];
    "Super+Q".action.close-window = [];

    # ── Apps ───────────────────────────────────────────────
    "Shift+Super+R" = {
      action.spawn = ["kitty" "-e" "btop"];
      repeat = false;
    };
    "Super+Return" = {
      action.spawn = ["kitty"];
      repeat = false;
    };
    "Super+W" = {
      action.spawn = ["zen-beta"];
      repeat = false;
    };
    "Super+N" = {
      action.spawn = ["kitty" "-e" "nvim"];
      repeat = false;
    };
    "Super+R" = {
      action.spawn = ["kitty" "-e" "fish" "-ic" "y"];
      repeat = false;
    };
    "Super+V" = {
      action.spawn = ["noctalia" "msg" "panel-toggle" "clipboard"];
      repeat = false;
    };
    "Super+Grave" = {
      action.spawn = ["vicinae" "vicinae://launch/core/search-emojis"];
      repeat = false;
    };
    "Super+Tab" = {
      action.toggle-overview = [];
      repeat = false;
    };
    "Super+Shift+Z" = {
      action.spawn = ["wooz" "--zoom-in" "10%" "--mouse-track" "--invert-scroll"];
      repeat = false;
    };
    "Super+M" = {
      action.spawn = ["kitty" "-e" "ncmpcpp"];
      repeat = false;
    };

    # ── Function keys ──────────────────────────────────────
    "Super+F1" = {
      action.spawn = ["~/.config/niri/scripts/kitty-sessions.sh"];
      repeat = false;
    };
    "Super+F2" = {
      action.spawn = ["~/.config/niri/scripts/phoneMirror"];
      repeat = false;
    };
    "Super+F3" = {
      action.spawn = ["kitty" "-e" "pulsemixer"];
      repeat = false;
    };
    "Super+F4" = {
      action.spawn = ["kitty" "-e" "tremc"];
      repeat = false;
    };

    # ── Wallpaper & screenshots ────────────────────────────
    "Super+F8" = {
      action.spawn = ["noctalia" "msg" "panel-toggle" "wallpaper"];
      repeat = false;
    };
    "Super+F9" = {
      action.spawn = ["noctalia" "msg" "wallpaper-random"];
      repeat = false;
    };
    "Super+Shift+S" = {
      action.spawn = ["noctalia" "msg" "screenshot-region"];
      repeat = false;
    };
    "Print" = {
      action.spawn = ["noctalia" "msg" "screenshot-fullscreen"];
      repeat = false;
    };

    # ── Misc ───────────────────────────────────────────────
    "Super+P" = {
      action.spawn = ["pkill" "-SIGUSR1" "wayscriber"];
      repeat = false;
    };
    "Mod+Shift+P".action.power-off-monitors = [];
    "Super+D" = {
      action.spawn = ["vicinae" "toggle"];
      repeat = false;
    };
    "Super+Shift+M" = {
      action.spawn = ["vicinae" "vicinae://launch/@anonmiraj/vicinae-extension-jellyfin-browser-0/jellyfin-browser"];
      repeat = false;
    };
    "Super+Alt+D" = {
      action.spawn = ["hyprwhspr-rs" "record" "toggle"];
      repeat = false;
    };
    "Super+Shift+Q" = {
      action.spawn = ["noctalia" "msg" "panel-toggle" "session"];
      repeat = false;
    };
    "Super+b" = {
      action.spawn = ["noctalia" "msg" "bar-toggle"];
      repeat = false;
    };

    # ── Mouse wheel — workspace navigation ─────────────────
    "Mod+WheelScrollDown" = {
      action.focus-workspace-down = [];
      cooldown-ms = 150;
    };
    "Mod+WheelScrollUp" = {
      action.focus-workspace-up = [];
      cooldown-ms = 150;
    };
    "Mod+shift+WheelScrollDown" = {
      action.move-column-to-workspace-down = [];
      cooldown-ms = 150;
    };
    "Mod+shift+WheelScrollUp" = {
      action.move-column-to-workspace-up = [];
      cooldown-ms = 150;
    };
    "Mod+WheelScrollRight".action.focus-column-right = [];
    "Mod+WheelScrollLeft".action.focus-column-left = [];
    "Mod+shift+WheelScrollRight".action.move-column-right = [];
    "Mod+shift+WheelScrollLeft".action.move-column-left = [];

    # ── Vim-style navigation ───────────────────────────────
    "Mod+H".action.focus-column-left = [];
    "Mod+J".action.focus-window-down = [];
    "Mod+K".action.focus-window-up = [];
    "Mod+L".action.focus-column-right = [];
    "Mod+Shift+H".action.focus-monitor-left = [];
    "Mod+Shift+J".action.focus-monitor-down = [];
    "Mod+Shift+K".action.focus-monitor-up = [];
    "Mod+Shift+L".action.focus-monitor-right = [];
    "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [];
    "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [];
    "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [];
    "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [];

    # ── Workspace switching ────────────────────────────────
    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;
    "Mod+Ctrl+1".action.move-column-to-workspace = 1;
    "Mod+Ctrl+2".action.move-column-to-workspace = 2;
    "Mod+Ctrl+3".action.move-column-to-workspace = 3;
    "Mod+Ctrl+4".action.move-column-to-workspace = 4;
    "Mod+Ctrl+5".action.move-column-to-workspace = 5;
    "Mod+Ctrl+6".action.move-column-to-workspace = 6;
    "Mod+Ctrl+7".action.move-column-to-workspace = 7;
    "Mod+Ctrl+8".action.move-column-to-workspace = 8;
    "Mod+Ctrl+9".action.move-column-to-workspace = 9;
  };
}
