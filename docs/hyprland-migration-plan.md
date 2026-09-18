# Niri → Hyprland migration plan (`niro`)

Status: proposal, not yet executed.
Scope: replace the Niri desktop session with Hyprland on host `niro`, keeping the
existing UX (noctalia shell, vicinae, kitty workflow, binds, window rules,
per-app behaviour) at parity — or better where Hyprland offers a stronger
equivalent.

## 0. Research notes (verified)

| Fact | Value |
| --- | --- |
| Hyprland in `nixos-unstable` right now | `0.56.2` (released 2026-08-05) |
| Hyprlang (`.conf`) status | Deprecated since **0.55**; 0.56.1 added an explicit deprecation notice for `.conf` configs. Still functional, but Lua is the way forward. |
| NixOS module | `programs.hyprland` with `enable`, `package`, `portalPackage`, `xwayland.enable`, `withUWSM`, `systemd.setPath.enable` |
| Home Manager module | `wayland.windowManager.hyprland`, options include `enable`, `package`, `portalPackage`, `configType` (`"hyprlang"` \| `"lua"`), `settings`, `submaps`, `plugins`, `extraConfig`, `extraLuaFiles`, `xdph.settings`, `systemd.*`, `xwayland.enable` |
| HM `configType` default | `lua` from `home.stateVersion >= 26.05`, otherwise `hyprlang`. Repo is on `home.stateVersion = "23.11"`, so the default today is the legacy `hyprlang`. |
| Scrolling layout | Built into Hyprland core since 0.5x — columns on an infinite tape, closest thing to niri semantics |
| Noctalia | Supports Hyprland; docs give exact autostart hook, workspace persistence rules and layer rules |
| Cachix | `hyprland.cachix.org` — only needed if using the Hyprland **flake** package, not the nixpkgs package |

Sources: Hyprland wiki (`Nix/Hyprland-on-NixOS`, `Nix/Hyprland-on-Home-Manager`,
`Nix/Cachix`, `Configuring/Layouts/Scrolling-Layout`, `Configuring/Core/*`),
Home Manager `modules/services/window-managers/hyprland/{default,lib}.nix`,
Noctalia docs `noctalia/compositor-settings/hyprland`.

## 1. Decisions to confirm before touching code

| # | Decision | Options | Recommendation |
| --- | --- | --- | --- |
| D1 | Hyprland source | (a) nixpkgs unstable = 0.56.2; (b) `github:hyprwm/Hyprland` flake = git main | **(a)**. Latest release, no cachix, no mesa/`nixpkgs.follows` pitfall, no separate `nixpkgs` input. Only go (b) if you need unreleased features. |
| D2 | Config format | (a) `configType = "lua"`; (b) `configType = "hyprlang"` (legacy `.conf`) | **(a)**. Upstream is deprecating `.conf`; HM emits `hyprland.lua` with the same declarative `settings` option. |
| D3 | Default layout | (a) `scrolling` (niri-like); (b) `dwindle` | **(a)**. Preserves niri muscle memory; set per-workspace overrides only where wanted. |
| D4 | Overview (`Super+Tab` today) | (a) `hyprexpo` official plugin; (b) noctalia overview; (c) drop | **(a)** if you actually use it, else (c). Hyprland has no built-in overview. |
| D5 | Cursor zoom (`niri-zoom`, `Ctrl+wheel`) | (a) built-in `cursor:zoom_factor` via `hyprctl eval`; (b) `hyprzoom` plugin | **(a)**. Zero extra dependency; built-in magnifier already tracks the cursor. |
| D6 | Session manager | (a) `programs.hyprland.withUWSM = true`; (b) plain launch | **(a)**. Recommended upstream; better systemd target handling, which also fits the existing `hyprwhspr-rs` / noctalia / vicinae user services. |
| D7 | Noctalia input | (a) keep `noctalia-shell` input; (b) migrate to `noctalia-dev/noctalia` | Keep (a) now, migrate later as a separate change. Not a Hyprland blocker. |
| D8 | Autostart model | (a) `hl.on("hyprland.start", ...)` exec_cmds; (b) systemd user services | (a) for the port, then move long-lived daemons (`mpd`, `kdeconnectd`, `transmission-daemon`) to systemd services opportunistically. |

## 2. File-level change map

### 2.1 NixOS layer

| File | Change |
| --- | --- |
| `modules/desktop.nix` | Remove `programs.niri.*`. Add `programs.hyprland = { enable = true; withUWSM = true; }`. Rework `xdg.portal.config` from `niri` to `hyprland`: drop the gnome ScreenCast/Screenshot overrides (XDPH handles both), keep `termfilechooser` as FileChooser, keep the `common` fallback. Drop `xdg-desktop-portal-wlr` from `extraPortals` (Hyprland has its own portal; the NixOS module also sets `enableWlrPortal = false`). |
| `nix/hosts/niro/default.nix` | Drop `inputs.niri.nixosModules.niri`. Keep `hardware.nvidia.*` as-is (already correct: `modesetting`, `powerManagement`, `open`, prime sync). Add no Hyprland-specific env for hybrid PRIME on day one; only tune if the discrete-GPU output misbehaves (see §5). |
| `nix/flake-file.nix` | Remove `niri` and `niri-zoom` inputs. Remove `https://niri.cachix.org` + its key from `nixConfig`. Do **not** add a `hyprland` input unless D1 picks the flake. |
| `cachix/niri.nix` | Delete. Add `cachix/hyprland.nix` only if D1 = flake. `cachix/noctalia.nix` stays. |
| `modules/pkgs.nix` | Remove `inputs.niri-zoom...default` from `environment.systemPackages`. Keep `xwayland-satellite` or drop it (Hyprland has native XWayland via `programs.hyprland.xwayland.enable`, default `true`) — recommend dropping. Optionally add `hyprland-qt-support` / `hyprqt6engine` if Qt apps look wrong. |
| `flake.nix` | Regenerate via `nix run .#write-flake` after the input changes. Never hand-edit. |

Note: `programs.xwayland.enable = true` in `modules/desktop.nix` and
`services.desktopManager.cosmic.enable = true` are unrelated to the compositor
switch; leave them unless you want to prune COSMIC too.

### 2.2 Home Manager layer

Mirror the existing `users/nir/niri/` layout as `users/nir/hyprland/`:

```
users/nir/hyprland/
  default.nix        # imports the rest
  core.nix           # hl.config: general/decoration/input/cursor/misc + hl.env
  monitors.nix       # hl.monitor + workspace rules (was outputs.nix)
  binds.nix          # hl.bind table
  rules.nix          # hl.window_rule + hl.layer_rule (was windowrules.nix)
  animations.nix     # hl.curve + hl.animation
  autostart.nix      # hl.on("hyprland.start", ...) (was spawn.nix)
  scripts.nix        # reuse the existing scripts/
  scripts/           # moved unchanged
```

See §3 for how each file maps. Because HM in Lua mode renders `settings`
attributes as `hl.<name>(...)` calls, and autostart/event hooks have no direct
`settings` shape, use `extraLuaFiles` to emit real Lua modules (each becomes
`~/.config/hypr/<name>.lua` and is `require`d from the generated
`hyprland.lua`). That keeps the multi-file structure you already have with niri.

`users/nir/home.nix`: replace `./niri` with `./hyprland` in `imports`.

Sketch:

```nix
# users/nir/hyprland/default.nix
{ ... }: {
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";           # D2
    systemd.enable = true;
    # only when D1 = flake:
    # package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    settings = { /* hl.config(...) values, see core.nix */ };
    extraLuaFiles = {
      "binds"    = ./binds.lua;
      "rules"    = ./rules.lua;
      "autostart" = ./autostart.lua;
    };
  };
}
```

Alternatively keep everything in `settings` + one `extraConfig` block; the
`extraLuaFiles` split is only about keeping files small.

## 3. Config translation map

### 3.1 Session / input / layout (`core.nix`)

niri (KDL) → Hyprland Lua via `hl.config({...})`:

| Niri | Hyprland |
| --- | --- |
| `input.keyboard.xkb.layout = "us,ara"` | `config.input.kb_layout = "us,ara"` |
| `input.keyboard.xkb.options = "grp:win_space_toggle, caps:escape, altwin:menu_win"` | `config.input.kb_options = "grp:win_space_toggle,caps:escape,altwin:menu_win"` |
| `input.keyboard.repeat-delay = 255` | `config.input.repeat_delay = 255` |
| `input.keyboard.repeat-rate = 40` | `config.input.repeat_rate = 40` |
| `input.keyboard.numlock = true` | `config.input.numlock_by_default = true` |
| `input.touchpad.tap = true` | `config.input.touchpad.tap_to_click = true` |
| `input.touchpad.natural-scroll = true` | `config.input.touchpad.natural_scroll = true` |
| `input.focus-follows-mouse.enable = true` | `config.input.follow_mouse = 1` |
| `input.workspace-auto-back-and-forth = true` | `config.binds.workspace_back_and_forth = true` |
| `layout.gaps = 4` | `config.general.gaps_in = 4`, `config.general.gaps_out = 4` |
| `layout.border.enable = false` | `config.general.border_size = 0` (or keep 2 if you want the focus ring look) |
| `layout.focus-ring.enable = true; width = 2` | `config.general.border_size = 2` + `config.general.col.active_border` / `col.inactive_border` |
| `layout.shadow.{softness,spread,offset,color}` | `config.decoration.shadow = { enabled = true; range; render_power; offset = {x;y}; color }` (Hyprland has no softness/spread; `range` + `render_power` are the knobs) |
| `blur.{noise,saturation}` | `config.decoration.blur = { enabled = true; size; passes; noise; contrast; brightness; vibrancy }` |
| `layout.preset-column-widths` / `default-column-width` | `config.scrolling.explicit_column_widths = "0.333,0.5,0.667"` / `config.scrolling.column_width = 0.5` |
| `prefer-no-csd = true` | No direct option. Keep `GTK_CSD=0` for GTK3 if needed; per-window via rules. |
| `screenshot-path` | N/A — noctalia owns screenshots today. |
| `hotkey-overlay.skip-at-startup` | N/A. |
| `environment.XDG_CURRENT_DESKTOP = "niri"` | Set by the module/UWSM. Do not override. |
| `environment.QT_QPA_PLATFORM = "wayland"` | `hl.env("QT_QPA_PLATFORM", "wayland;xcb")` |
| `environment.ELECTRON_OZONE_PLATFORM_HINT = "auto"` | `hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")` |
| `environment.NIXOS_OZONE_WL = "1"` | already a NixOS session var; fine as-is |
| `cursor.theme = "Bibata_Ghost"; size = 37` | `hl.env("XCURSOR_THEME", "Bibata_Ghost")`, `hl.env("XCURSOR_SIZE", "37")`, plus `config.cursor.*` for behaviour |
| `cursor.hide-when-typing = true` | No equivalent. Closest: `config.cursor.inactive_timeout`. |
| `layer-rules` for quickshell backdrop | `hl.layer_rule` for noctalia (see §3.4) |
| `debug.honor-xdg-activation-with-invalid-serial` | N/A (niri debug knob). |
| `config-notification.disable-failed` | N/A. |

Also set `config.misc.*` deliberately (e.g. `vfr`, `disable_hyprland_logo`), and
do **not** enable `LIBVA_DRIVER_NAME=nvidia` / `__GLX_VENDOR_LIBRARY_NAME=nvidia`
from the wiki NVIDIA page — those are for NVIDIA-only setups, this box is hybrid
Intel + NVIDIA PRIME. Add them only if you actually switch to discrete-only.

### 3.2 Monitors (`outputs.nix` → `monitors.nix`)

```lua
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", scale = 1, position = "0x0" })
hl.monitor({ output = "eDP-1",    mode = "1920x1080@144", scale = 1, position = "2560x0" })
```

Named workspaces `browser` / `chat` pinned to the laptop panel:

```lua
hl.workspace_rule({ workspace = "name:browser", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "name:chat",    monitor = "eDP-1" })
```

Noctalia additionally wants persistent numeric workspaces for its workspace
indicator; add `persistent = true` + `default_name` rules if you use the numeric
workspaces heavily.

### 3.3 Binds (`binds.nix`)

Shape: `settings.bind = [ { _args = [ "<keys>" (mkLuaInline "<dispatcher>") ]; } ]`,
or a raw `hl.bind(...)` in an `extraLuaFiles` module. Use the latter for
readability — this table is large.

| Niri action | Hyprland Lua |
| --- | --- |
| `action.spawn = [ "kitty" ]` | `hl.dsp.exec_cmd("kitty")` |
| `action.close-window` | `hl.dsp.window.close()` |
| `action.toggle-window-floating` | `hl.dsp.window.float()` |
| `action.maximize-column` | `hl.dsp.window.fullscreen({ mode = "maximized" })` |
| `action.fullscreen-window` | `hl.dsp.window.fullscreen()` |
| `action.power-off-monitors` | `hl.dsp.dpms({ action = "disable" })` — wrap in `hl.timer(..., { timeout = 500, type = "oneshot" })` per upstream warning about binding DPMS directly |
| `action.power-on-monitors` | `hl.dsp.dpms({ action = "enable" })` (same timer caveat) |
| `action.focus-column-left/right` | `hl.dsp.focus({ direction = "l" / "r" })` |
| `action.focus-window-up/down` | `hl.dsp.focus({ direction = "u" / "d" })` |
| `action.focus-workspace = N` | `hl.dsp.focus({ workspace = "N", on_current_monitor = true })` — stays on the focused monitor; the workspace swaps over rather than teleporting you |
| `action.move-column-to-workspace = N` | `hl.dsp.window.move({ workspace = "N", follow = false })` — no `on_current_monitor` equivalent exists in 0.56.2, so this is a plain global move |
| `action.focus-workspace-down/up` | `hl.dsp.focus({ workspace = "r+1" / "r-1" })` |
| `action.move-column-to-workspace-down/up` | `hl.dsp.window.move({ workspace = "r+1" / "r-1", follow = false })` |
| `action.focus-monitor-{left,right,up,down}` | `hl.dsp.focus({ monitor = "l" / "r" / "u" / "d" })` |
| `action.move-column-to-monitor-*` | `hl.dsp.window.move({ monitor = "l" / "r" / "u" / "d" })` |
| `action.toggle-overview` | `hl.plugin.scrolloverview.overview("toggle all")` on `Super+Tab` (D4) |
| `Mod+WheelScroll*` focus/move | `hl.bind("SUPER + mouse_down", ...)` with `hl.dsp.focus({ workspace = "r+1" })` |
| `Ctrl+WheelScroll` niri-zoom | `hl.dsp.exec_cmd("hyprctl eval 'hl.config({cursor = {zoom_factor = ...}})'")` (D5) |
| noctalia/vicinae/kitty/btop/etc. spawns | unchanged command strings, wrapped in `hl.dsp.exec_cmd` |
| media keys (`XF86Audio*`) | unchanged, in `hl.dsp.exec_cmd("noctalia msg ...")`. `allow-when-locked` has no equivalent — handle via `noctalia` session behaviour or `hyprlock` if you add it. |

`repeat = false` has no direct analogue; wrap in a no-repeat bind flag if needed
(check `Configuring/Core/Binds/Flags` at implementation time).

### 3.4 Window + layer rules (`windowrules.nix` → `rules.nix`)

| Niri rule | Hyprland |
| --- | --- |
| `matches = [{}]` global defaults | global `hl.config({decoration = ...})` + `general` |
| `geometry-corner-radius` + `clip-to-geometry` | `decoration.rounding` globally, `rounding = N` per-window |
| `background-effect.blur = true; xray = true` | global `decoration.blur.enabled = true`; `xray = true` window rule for the xray part |
| `is-urgent = true` → red shadow | `match = { urgent = ... }` if supported, else `hl.on("window.urgent", ...)` + `border_color` |
| `app-id = "^org\\.telegram\\.desktop$"` | `match = { class = "^org\\.telegram\\.desktop$" }` |
| `title = "^Media viewer$"` | `match = { title = "^Media viewer$" }` (matches initial title only — make sure that is acceptable) |
| `open-on-workspace = "chat"` | `workspace = "name:chat"` |
| `open-floating = true` | `float = true` |
| `open-maximized = true` | `maximize = true` |
| `open-on-output = "HDMI-A-1"` | `monitor = "HDMI-A-1"` |
| `default-column-width = { proportion = 0.5 }` | `scrolling_width = 0.5` |
| `opacity = 0.95` | `opacity = "0.95"` (append `" override"` if you want absolute) |
| `variable-refresh-rate = true` | `no_vrr` is the inverse rule; enable `misc.vrr` globally and disable per window |
| `is-window-cast-target` | no rule prop; use an event hook + `border_color` if you still want the pink ring |
| niri `baba-is-float`, `scroll-factor`, `open-maximized-to-edges`, `default-window-height`, `default-floating-position` | approximate with `float`, `scroll_touchpad`/`scroll_mouse`, `size`, `move` |

Layer rule for noctalia (replaces the quickshell `place-within-backdrop` rule):

```lua
hl.layer_rule({
  name = "noctalia",
  match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
```

### 3.5 Animations (`animations.nix`)

`hl.curve(NAME, { type = "spring", mass = 1, stiffness = S, damping = D })` plus
`hl.animation({ leaf = ..., enabled = true, spring = NAME, speed = ... })`.
Mapping niri's springs is mechanical: niri `damping-ratio` → Hyprland
`damping = 2 * sqrt(stiffness)` roughly for critical damping; carry `stiffness`
across and tune by eye. niri `easing` curves map to `hl.curve(NAME, {type =
"bezier", points = {...}})`.

Leaves to cover: `global`, `windows`, `windowsIn/Out/Move`, `fade*`, `layers*`,
`workspaces`, `border`, `zoomFactor` (the last one covers cursor zoom).

### 3.6 Autostart (`spawn.nix` → `autostart.nix`)

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("wl-paste --type text  --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("trash-empty 30")
  hl.exec_cmd("mpd")
  hl.exec_cmd("kdeconnectd")
  hl.exec_cmd("transmission-daemon")
  hl.exec_cmd("~/.local/bin/lowbattery.sh")
  hl.exec_cmd("noctalia")            -- noctalia's documented autostart
  hl.exec_cmd("sleep 5 && mpd-mpris")
end)
```

Drops: `xwayland-satellite` (native XWayland), `niri-zoomd` (uses built-in
cursor zoom). Keep `hyprwhspr-rs` enabled at the NixOS level; it is compositor
agnostic and already works under niri.

## 4. Known behavioural gaps (accept or work around)

1. **Scrolling ≠ niri scrolling.** Hyprland's scrolling layout is close but not
   identical: `Super+Tab` overview, niri's column-width presets (`Mod+R`
   ratchet), and niri's `baba-is-float` have no 1:1 counterpart.
2. **Window title matching is initial-title only** for static rules. Rules
   relying on a title set after map (e.g. media viewers) may need event hooks.
3. **CSD handling** differs; `prefer-no-csd` has no equivalent. Some GTK apps
   will show client-side decorations.
4. **`allow-when-locked` binds** have no equivalent until a lock screen is
   added. Media keys while locked may not work.
5. **Mouse wheel binds** need `binds.scroll_event_delay` tuning to feel like
   niri's `cooldown-ms = 150`.
6. **Hybrid NVIDIA PRIME under Hyprland** is the highest-risk area. niri worked
   with the current setup; Hyprland's multi-GPU handling (aquamarine) may need
   `AQ_DRM_DEVICES` or `AQ_FORCE_LINEAR_BLIT=0` if the HDMI-A-1 output attached
   to the NVIDIA GPU misbehaves. Budget a debugging session for this.
7. **Niri config validation** (`niri validate` via `runCommand`) disappears.
   HM validates nothing; rely on `hyprctl configerrors` / startup warnings.

## 5. Execution order

1. **Branch + baseline.** `git switch -c feat/hyprland`. Note current niri commit
   for rollback. Optionally keep Niri enabled during the migration so both
   sessions are selectable in Ly.
2. **NixOS layer.** `modules/desktop.nix` (`programs.hyprland`, portals),
   `nix/hosts/niro/default.nix`, `modules/pkgs.nix`. Regenerate:
   `nix run .#write-flake`. Apply: `sudo nixos-rebuild switch --flake .#niro`.
   Verify `start-hyprland` exists and a session appears in Ly.
3. **Skeleton HM config.** `users/nir/hyprland/` with `enable = true`,
   `configType = "lua"`, monitors + one bind. Rebuild, log in, confirm it starts
   and `hyprctl monitors` matches the niri layout.
4. **Port core settings** (input, layout/scrolling, decoration, cursor, env).
5. **Port animations.**
6. **Port window + layer rules**, noctalia layer rule, noctalia autostart hook.
7. **Port binds** in batches: window management → workspaces → spawns → media →
   wheel → zoom.
8. **Port autostart + scripts.** Move `users/nir/niri/scripts/` to
   `users/nir/hyprland/scripts/` and update `scripts.nix` paths.
9. **UX pass.** Gap/border/shadow tuning, scroll delay, workspace persistence for
   noctalia, `hyprexpo` if wanted.
10. **Create the Hyprland session preference** (Ly default session) and drop the
    niri session once parity is confirmed.

## 6. Validation checklist

- `nix flake check`
- `nix run .#write-flake` yields no diff after the input removals
- `nix fmt` (or `nix run .#formatter`) before commit
- `hyprctl monitors all` → both outputs, correct modes/positions
- `hyprctl configerrors` → empty
- `hyprctl binds` → no duplicate/unbound keys
- `hyprctl clients` → Telegram/Vesktop land on `chat`, Zen on `browser`
- Noctalia bar renders, workspace indicator tracks, panels toggle from binds
- vicinae toggles (`Super+D`), emoji/clipboard providers work
- `hyprwhspr-rs record toggle` works
- XWayland app (e.g. Steam, an X11 game) starts
- External monitor on the NVIDIA GPU renders with acceptable latency
- Suspend/resume + NVENC/NVDEC (if used)

## 7. Rollback

Niri stays installed (flake input + `programs.niri.enable`) until step 10.
Rollback = revert the branch (`git revert`/`git checkout main`) and
`sudo nixos-rebuild switch`. If the niri inputs are already removed, restore them
in `nix/flake-file.nix`, `nix run .#write-flake`, rebuild.

## 8. Decisions taken

| # | Decision | Choice |
| --- | --- | --- |
| D1 | Hyprland source | nixpkgs unstable `0.56.2` (no Hyprland flake input, no hyprland cachix) |
| D2 | Config format | `configType = "lua"` |
| D3 | Default layout | `general.layout = "scrolling"` |
| D4 | Overview (`Super+Tab`) | **`hyprland-scroll-overview`** (local package, `pkgs/scrolloverview`). hyprexpo is dead (removed at v0.54.0, absent from nixpkgs), noctalia has no overview, and hyprshell was tried and rejected. Plugin is built from source against this repo's Hyprland so the API handshake matches. |
| D5 | Cursor zoom | Built-in `cursor.zoom_factor` via `hl.get_config` / `hl.config`. `niri-zoom` no longer needed. |
| D6 | Session manager | **No UWSM, but `hyprland.systemd.enable = true`.** See the
| | | correction below — the wiki is `main`-only here. |
| D7 | Noctalia input | Kept on `noctalia-shell` for now. |
| D8 | Autostart model | `hl.on("hyprland.start", ...)` exec_cmds. |

## 9. Implementation status

Done and verified:

- `users/nir/hyprland/{default,core,monitors,binds,rules,animations,autostart,scripts}.nix`
  created; scripts moved to the shared `users/nir/scripts/` so Niri keeps
  working during the migration.
- `modules/desktop.nix`: `programs.hyprland.enable = true`, portals switched
  from `niri` to `hyprland` (XDPH for ScreenCast/Screenshot),
  `xdg-desktop-portal-wlr` dropped.
- `users/nir/home.nix` imports `./hyprland` (Niri still imported too).
- `nix eval .#nixosConfigurations.niro.config.system.build.toplevel.drvPath`
  succeeds.
- The generated `~/.config/hypr/hyprland.lua` was checked with
  `Hyprland --verify-config` (Hyprland 0.56.2) and reports `config ok`, plus
  `luac -p` for syntax.

Fixes found by `--verify-config` during the port (worth knowing):

- `hl.curve` spellt `dampening`, not `damping`, in 0.56.2.
- `hl.animation` requires `bezier = "name"` / `spring = "name"`, not
  `curve = "name"`.
- `decoration.shadow.offset` is a vec2 and needs a 2-element list, not an
  `{ x; y; }` attrset.

### Correction: session targets on Hyprland 0.56.2

The Hyprland wiki page says `hyprland-session.target` is "handled
automatically" and that manual `systemctl` target juggling should be removed.
**That documents `main`, not 0.56.2.** The 0.56.2 binary only knows
`HYPRLAND_NO_SD_NOTIFY` / `HYPRLAND_NO_SD_VARS`; grepping
`.Hyprland-wrapped` for `hyprland-session.target` or `graphical-session.target`
finds nothing, and after a real login `graphical-session.target` was
`inactive`.

Consequence: noctalia, vicinae, jellyfin-mpv-shim and stasis all have
`WantedBy=graphical-session.target` and never started → empty desktop with no
bar. Niri never had this problem because `niri-session` runs
`systemctl --user start niri.service`, and `niri.service` carries
`BindsTo=graphical-session.target`.

Fix: keep Home Manager's `wayland.windowManager.hyprland.systemd.enable = true`.
It installs `hyprland-session.target` (with `BindsTo=graphical-session.target`)
and emits `systemctl --user start hyprland-session.target`. `BindsTo` pulls the
target in as a dependency, which is the only way in: `graphical-session.target`
sets `RefuseManualStart=yes`, so a direct `systemctl --user start
graphical-session.target` is refused.

Verified live after switching: `graphical-session.target` active, and
noctalia / vicinae / jellyfin-mpv-shim / stasis all `active`, with noctalia
rendering its `bar-default`, `dock`, `wallpaper` and desktop-widget layers.

Corollary: do **not** also `hl.exec_cmd("noctalia")` in autostart — the user
service already starts it and you would get two shells.

### Live session audit (Hyprland 0.56.2, real login)

- `hyprctl configerrors` empty; `configProvider: lua`
- monitors: `eDP-1 1920x1080@144.003 at 2560x0`, `HDMI-A-1 2560x1440@144 at 0x0`
  — matches the niri layout, and proves hybrid NVIDIA PRIME with the dGPU
  driving HDMI-A-1 works (risk §4 item 6 did not materialise)
- 83 binds loaded
- `general:layout=scrolling`, `gaps_in="4 4 4 4"`, `border_size=2`,
  `rounding=12`, `misc:vrr=2`, `input:kb_layout=us,ara`,
  `scrolling:column_width=0.5`, `binds:scroll_event_delay=150`
- `hl.env` reached spawned apps: `XCURSOR_SIZE=37`, `XCURSOR_THEME=Bibata_Ghost`,
  `QT_QPA_PLATFORM=wayland;xcb`, `NIXOS_OZONE_WL=1`,
  `ELECTRON_OZONE_PLATFORM_HINT=auto`

Note: `hl.env` only affects Hyprland and its children. systemd user services
(noctalia, vicinae) inherit from the systemd user manager instead, so cursor
theme/size do not reach them. Same behaviour niri had.

### Plugin validation: hyprland-scroll-overview

Chosen for the overview (D4) and built as a local package. Verification that
actually mattered:

- **ABI match, decided by content not guesswork.** Upstream's `hyprpm` pins stop
  at v0.55.4 and their flake pins Hyprland at a 2026-07-14 commit, both older
  than 0.56.2. Rather than assume, the built `.so` was grepped: it embeds
  `efb50993780079460b0cbed1363e2166a2de1d9f`, byte-identical to the running
  compositor's `Version ABI string`, so `__hyprland_api_get_client_hash`
  matches. 0 unresolved `ldd` deps; exports `pluginAPIVersion`/`pluginInit`/
  `pluginExit`. Building against the same Hyprland as the session is what makes
  this hold.
- **`settings.plugin` is wrong.** Home Manager renders each `settings` key as
  `hl.<name>(...)`, so `settings.plugin = {...}` becomes `hl.plugin({...})` — and
  `hl.plugin` is a *table*, not a function. Hyprland aborts with
  `attempt to call a table value (field 'plugin')`. The plugin config must live
  under `settings.config.plugin.scrolloverview`, i.e.
  `hl.config({ plugin = { scrolloverview = {...} } })`, matching upstream docs.
- **`Hyprland --verify-config` cannot validate plugin options, by design.** It
  returns from `CCompositor::initServer` before `g_pPluginSystem` is created, so
  no plugin ever loads and every `plugin:scrolloverview:*` key reads as
  "unknown config key" (exit 1). This is a false negative, not a breakage.
  At runtime the sequence is: the lua script records a pending plugin load →
  `Config::mgr()->handlePluginLoads()` dlopens it in `STAGE_LATE` →
  `pluginsChanged` triggers a full `reload()` → the config is re-parsed with the
  plugin's keys registered, and the stale errors are discarded. Confirmed live:
  after the switch, all 8 `plugin:scrolloverview:*` options report the configured
  values and `hyprctl configerrors` is empty.
- **Named workspaces use negative IDs.** `browser`/`chat` show as `-1337`/
  `-1338`, which looks alarming but is Hyprland's internal allocation for
  purely-named workspaces. Confirmed not special: `hyprctl monitors -j` reports
  `specialWorkspace: ""` for both monitors, and `tiledLayout: "scrolling"`.

Remaining:

1. `sudo nixos-rebuild switch` (build pre-staged) so the session-target fix is
   committed to the system, then re-login once to confirm a cold start brings
   noctalia/vicinae up without help.
2. Tune animations (`speed`/styles) and blur/shadow values by eye; the spring
   numbers are the mechanical niri translation, not a taste pass.
3. Re-add `prefer-no-csd` behaviour if the CSD differences are annoying.
4. Visually confirm the scroll-overview renders when `Super+Tab` is pressed (the
   config, bind and plugin load are all verified; only the rendering was not
   observable from a terminal).
5. `nix fmt`, commit, then once parity is confirmed delete Niri:
   `programs.niri.*` in `modules/desktop.nix`, `./niri` in
   `users/nir/home.nix`, the `niri` + `niri-zoom` inputs and
   `niri.cachix.org` in `nix/flake-file.nix`, `cachix/niri.nix`, the
   `niri-zoom` package in `modules/pkgs.nix`, then
   `nix run .#write-flake` and `users/nir/niri/`.
