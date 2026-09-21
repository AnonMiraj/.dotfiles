# Keybinds (was binds.nix).
#
# In Lua config mode each `settings.bind` entry is a list rendered as
# `hl.bind(<key>, <dispatcher>)`, so `_args` holds the key and a raw Lua
# dispatcher expression built with lib.generators.mkLuaInline.
#
# NOTE: SUPER + Tab toggles the hyprland-scroll-overview plugin (see
# scrolloverview.nix). The dispatcher is the plugin's Lua entry point
# hl.plugin.scrolloverview.overview("toggle all").
{lib, ...}: let
  lua = lib.generators.mkLuaInline;

  # keys -> raw Lua dispatcher expression
  mkb = keys: expr: {_args = [keys (lua expr)];};

  # Same, plus bind flags: mouse drag/resize needs `{ mouse = true }`.
  mkbFlag = keys: expr: flags: {_args = [keys (lua expr) flags];};

  # Holding the key repeats the dispatcher. Hyprland's flag is spelled
  # `repeating` in `hl.bind` opts, and the combo is rejected alongside
  # `long_press`/`release`, so it gets its own helper.
  mkbRepeat = keys: expr: {_args = [keys (lua expr) {repeating = true;}];};

  # keys -> command string, run through `sh -c`
  exec = keys: cmd: mkb keys "hl.dsp.exec_cmd(${builtins.toJSON cmd})";

  # noctalia IPC helper
  noctalia = keys: args: exec keys "noctalia msg ${args}";

  # Same, for continuous controls: volume and brightness ramp while held.
  noctaliaRepeat = keys: args: mkbRepeat keys "hl.dsp.exec_cmd(${builtins.toJSON "noctalia msg ${args}"})";

  # direction helpers
  focusDir = keys: dir: mkb keys "hl.dsp.focus({ direction = ${builtins.toJSON dir} })";
  moveToMonitor = keys: dir: mkb keys "hl.dsp.window.move({ monitor = ${builtins.toJSON dir} })";
  focusMonitor = keys: dir: mkb keys "hl.dsp.focus({ monitor = ${builtins.toJSON dir} })";
  # Relative workspace moves go through hyprsplit's hs.dsp (see hyprsplit.nix).
  # Hyprland's own hl.dsp.focus({workspace=...}) targets the single global
  # workspace pool, which is what made switching jump monitors. hs.dsp.focus/move
  # resolve the workspace on the CURRENT monitor at dispatch time. `hs` is a
  # global set by the hyprsplit extraLuaFiles entry, which Home Manager emits
  # before these binds.
  #
  # Relative forms hyprsplit understands:
  #   "+1"/"-1" no looping, "r+1"/"r-1" looping, "e±1"/"m±1" excluding empty
  #
  # Absolute keys do not use hs.dsp; they call ws_focus/ws_move, defined in
  # hyprsplit.nix, which resolve the slot first and then dispatch the plain id.
  moveToWs = keys: ws: mkb keys "hs.dsp.window.move({ workspace = ${builtins.toJSON ws}, follow = false })";

  # Workspace 1..10 per monitor. Key 10 is `0`, matching upstream's example.
  # The keys go through ws_focus / ws_move (hyprsplit.nix): n resolves to the
  # n-th existing workspace on the focused monitor, and past the end it creates
  # the next workspace (SUPER + 4 with two open lands on a fresh 3) rather than
  # asking for raw id 4. Wrapped in a function so the lookup runs on keypress.
  wsKey = n:
    if n == 10
    then "0"
    else toString n;
  wsFocus = map (n:
    mkb "SUPER + ${wsKey n}" ''
      function()
        ws_focus(${toString n})
      end
    '')
  (lib.range 1 10);
  wsMove = map (n:
    mkb "SUPER + SHIFT + ${wsKey n}" ''
      function()
        ws_move(${toString n}, false)
      end
    '')
  (lib.range 1 10);
in {
  wayland.windowManager.hyprland.settings.bind =
    [
      # ── Media keys ───────────────────────────────────────
      # Sliders repeat while held; toggles (mute/mic/transport) must not, or
      # holding the key would spam them.
      (noctaliaRepeat "XF86AudioRaiseVolume" "volume-up 3")
      (noctaliaRepeat "XF86AudioLowerVolume" "volume-down 3")
      (noctalia "XF86AudioMute" "volume-mute")
      (noctalia "XF86AudioMicMute" "mic-mute")
      (noctaliaRepeat "XF86MonBrightnessUp" "brightness-up current 5")
      (noctaliaRepeat "XF86MonBrightnessDown" "brightness-down current 5")
      (noctalia "XF86AudioPlay" "media toggle")
      (noctalia "XF86AudioPause" "media toggle")
      (noctalia "XF86AudioNext" "media next")
      (noctalia "XF86AudioPrev" "media previous")
      (noctalia "XF86AudioStop" "media stop")
      (noctaliaRepeat "SUPER + U" "brightness-up current 5")
      (noctaliaRepeat "SUPER + SHIFT + U" "brightness-down current 5")
      # ── Clipboard & tools ────────────────────────────────
      # niri had both `Mod+V` (vicinae) and `Super+V` (noctalia) on the same
      # key; they are split here so no bind is shadowed.
      (exec "SUPER + V" "noctalia msg panel-toggle clipboard")
      (exec "SUPER + CTRL + V" "vicinae vicinae://launch/clipboard/history")
      (noctalia "SUPER + CTRL + N" "panel-toggle control-center")
      (noctalia "SUPER + ALT + L" "session lock")

      # ── Window management ────────────────────────────────
      (mkb "SUPER + F" "hl.dsp.window.fullscreen({ mode = \"maximized\" })")
      (mkb "SUPER + SHIFT + F" "hl.dsp.window.fullscreen()")
      # Sticky float: SUPER + S floats, pins and raises the active window, and
      # pressing it again drops both. `pin` alone is ignored on tiled windows
      # (window-rule docs: "pinning is ignored for non-floating windows"), and it
      # is also refused on fullscreen ones -- ConfigActions::pinWindow returns
      # "Window does not qualify to be pinned" -- so float has to come first and
      # the window must not be fullscreen yet.
      #
      # `bring_to_top` (CA::alterZOrder("top")) is the only always-on-top
      # Hyprland has; pinned floats already render above unpinned ones.
      #
      # Key must stay unique: duplicate binds are not deduplicated
      # (MatchResolver puts every full match in `immediate`, Manager invokes them
      # all), and SUPER + SHIFT + S below is the region screenshot.
      (mkb "SUPER + S" ''
        function()
          local w = hl.get_active_window()
          if w == nil then return end
          if w.pinned then
            hl.dispatch(hl.dsp.window.pin({ window = w, action = "disable" }))
            hl.dispatch(hl.dsp.window.float({ window = w, action = "disable" }))
          else
            hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
            hl.dispatch(hl.dsp.window.pin({ window = w, action = "enable" }))
            hl.dispatch(hl.dsp.window.bring_to_top())
          end
        end
      '')
      (mkb "SUPER + Q" "hl.dsp.window.close()")
      (exec "SUPER + CTRL + Q" "hyprctl kill")
      (mkbFlag "SUPER + mouse:272" "hl.dsp.window.drag()" {mouse = true;})
      (mkbFlag "SUPER + mouse:273" "hl.dsp.window.resize()" {mouse = true;})
      # ── Apps ─────────────────────────────────────────────
      (exec "SHIFT + SUPER + R" "kitty -e btop")
      (exec "SUPER + Return" "kitty")
      (exec "SUPER + W" "zen-beta")
      (exec "SUPER + N" "kitty -e nvim")
      (exec "SUPER + R" "kitty -e fish -ic y")
      (exec "SUPER + Grave" "vicinae vicinae://launch/core/search-emojis")
      (exec "SUPER + SHIFT + Z" "wooz --zoom-in 10% --mouse-track --invert-scroll")
      (exec "SUPER + M" "kitty -e ncmpcpp")

      # ── Function keys ────────────────────────────────────
      (exec "SUPER + F1" "~/.config/hypr/scripts/kitty-sessions.sh")
      (exec "SUPER + F2" "~/.config/hypr/scripts/phoneMirror")
      (exec "SUPER + F3" "kitty -e pulsemixer")
      (exec "SUPER + F4" "kitty -e tremc")

      # ── Wallpaper & screenshots ──────────────────────────
      (noctalia "SUPER + F8" "panel-toggle wallpaper")
      (noctalia "SUPER + F9" "wallpaper-random")
      (noctalia "SUPER + SHIFT + S" "screenshot-region")
      (noctalia "Print" "screenshot-fullscreen")

      # ── Overview ─────────────────────────────────────────
      # submap_universal: the scrolloverview submap swallows normal binds while
      # it is active, so this one is marked to stay live and close the overview.
      (mkbFlag "SUPER + Tab" ''
        function()
          hl.plugin.scrolloverview.overview("toggle all")
        end
      '' {submap_universal = true;})
      (mkb "SUPER + SHIFT + Tab" "hl.dsp.focus({ last = true })")
      (mkb "SUPER + CTRL + Tab" ''
        function()
          hl.dispatch(hl.dsp.window.move({ monitor = "+1", follow = true }))
        end
      '')

      # ── Misc ─────────────────────────────────────────────
      (exec "SUPER + P" "pkill -SIGUSR1 wayscriber")
      # Upstream warns against binding DPMS directly, so go through a timer.
      (mkb "SUPER + SHIFT + P" ''
        function()
          hl.timer(function()
            hl.dispatch(hl.dsp.dpms({ action = "disable" }))
          end, { timeout = 500, type = "oneshot" })
        end
      '')
      (exec "SUPER + D" "vicinae toggle")
      (exec "SUPER + SHIFT + M" "vicinae vicinae://launch/@anonmiraj/vicinae-extension-jellyfin-browser-0/jellyfin-browser")
      # hyprwhspr-rs has no hotkey of its own - the binary contains no evdev,
      # grab or /dev/input references - so this bind is the only way to start a
      # recording, and a compositor-side bind is what its CLI `record` exists
      # for. Nothing to double-fire: there is no second listener on this key.
      (exec "SUPER + ALT + D" "hyprwhspr-rs record toggle")
      (noctalia "SUPER + SHIFT + Q" "panel-toggle session")
      (noctalia "SUPER + b" "bar-toggle")

      # ── Scrolling layout ─────────────────────────────────
      # The scrolling layout gives columns on an infinite tape. These expose
      # the column operations our config never bound, so the layout behaves
      # like niri's columns rather than a plain tiling WM.
      #
      # `layout` messages are documented on the Scrolling layout wiki page.
      #
      # -conf/+conf cycles the explicit_column_widths set in core.nix
      # (0.333 / 0.5 / 0.667) instead of a free-form resize.
      (mkb "SUPER + equal" "hl.dsp.layout(\"colresize +conf\")")
      (mkb "SUPER + minus" "hl.dsp.layout(\"colresize -conf\")")
      # fit expand: grow the column to take the remaining free space
      (mkb "SUPER + SHIFT + equal" "hl.dsp.layout(\"fit expand\")")
      # move/swap columns along the tape
      (mkb "SUPER + period" "hl.dsp.layout(\"move +col\")")
      (mkb "SUPER + comma" "hl.dsp.layout(\"move -col\")")
      (mkb "SUPER + SHIFT + period" "hl.dsp.layout(\"swapcol r\")")
      (mkb "SUPER + SHIFT + comma" "hl.dsp.layout(\"swapcol l\")")
      # consume_or_expel: fold the focused window into the previous column,
      # or expel it back out when it is already alone. This is niri's core
      # column manipulation and the one worth learning.
      (mkb "SUPER + C" "hl.dsp.layout(\"consume_or_expel prev\")")
      # promote: give the focused window its own column
      (mkb "SUPER + CTRL + C" "hl.dsp.layout(\"promote\")")
      # inhibit_scroll: freeze the tape so the view stops following focus
      (mkb "SUPER + i" "hl.dsp.layout(\"inhibit_scroll\")")

      # ── Vim-style navigation ─────────────────────────────────
      (focusDir "SUPER + H" "l")
      (focusDir "SUPER + J" "d")
      (focusDir "SUPER + K" "u")
      (focusDir "SUPER + L" "r")
      (focusMonitor "SUPER + SHIFT + H" "l")
      (focusMonitor "SUPER + SHIFT + J" "d")
      (focusMonitor "SUPER + SHIFT + K" "u")
      (focusMonitor "SUPER + SHIFT + L" "r")
      (moveToMonitor "SUPER + SHIFT + CTRL + H" "l")
      (moveToMonitor "SUPER + SHIFT + CTRL + J" "d")
      (moveToMonitor "SUPER + SHIFT + CTRL + K" "u")
      (moveToMonitor "SUPER + SHIFT + CTRL + L" "r")

      # NOTE: not SUPER + grave. SUPER + Grave is already the vicinae emoji
      # picker, and Hyprland resolves bind keys with XKB_KEYSYM_CASE_INSENSITIVE
      # (KeybindManager.cpp), so 'grave' and 'Grave' are the same key - binding
      # one silently shadowed the other. Verified against `hyprctl binds`
      # instead, which lists the resolved key.
      (mkb "SUPER + apostrophe" "hl.dsp.workspace.toggle_special(${builtins.toJSON "scratchpad"})")
      # follow = false is the silent form: the window lands there, focus stays put
      # on the workspace it came from.
      (mkb "SUPER + SHIFT + apostrophe" "hl.dsp.window.move({ workspace = ${builtins.toJSON "special:scratchpad"}, follow = false })")

      # ── Workspaces ───────────────────────────────────────
    ]
    ++ wsFocus
    ++ wsMove
    ++ [
      # ── Mouse wheel — workspace / column navigation ──────
      # ws_cycle walks the occupied workspaces on the active monitor plus one
      # empty workspace past the last of them, then wraps.
      (mkb "SUPER + mouse_down" ''
        function()
          ws_cycle(1)
        end
      '')
      (mkb "SUPER + mouse_up" ''
        function()
          ws_cycle(-1)
        end
      '')
      (moveToWs "SUPER + SHIFT + mouse_down" "r+1")
      (moveToWs "SUPER + SHIFT + mouse_up" "r-1")
      (mkb "SUPER + mouse_left" "hl.dsp.focus({ direction = \"l\" })")
      (mkb "SUPER + mouse_right" "hl.dsp.focus({ direction = \"r\" })")
      (mkb "SUPER + SHIFT + mouse_left" "hl.dsp.layout(\"move +col\")")
      (mkb "SUPER + SHIFT + mouse_right" "hl.dsp.layout(\"move -col\")")

      # ── Mouse wheel + Ctrl + Super — cursor zoom ──────────
      # Hyprland has a built-in cursor magnifier (cursor.zoom_factor), so the
      # niri-zoom flake and its niri-zoomd daemon are no longer needed.
      # Zoom is relative, so read the current value before writing it back.
      #
      # SUPER is in the combination on purpose. Plain CTRL + wheel is the zoom
      # gesture in most applications (browsers, editors, terminals), and binding
      # it in the compositor took it away from them. niri's zoom was
      # Ctrl+WheelScroll; the extra modifier keeps the two zooms apart.
      (mkb "SUPER + CTRL + mouse_up" ''
        function()
          local cur = hl.get_config("cursor.zoom_factor")
          hl.config({ ["cursor.zoom_factor"] = math.min(cur + 0.5, 10.0) })
        end
      '')
      (mkb "SUPER + CTRL + mouse_down" ''
        function()
          local cur = hl.get_config("cursor.zoom_factor")
          hl.config({ ["cursor.zoom_factor"] = math.max(cur - 0.5, 1.0) })
        end
      '')
      (mkb "CTRL + SUPER + Z" ''
        function()
          hl.config({ ["cursor.zoom_factor"] = 1.0 })
        end
      '')
    ];
}
