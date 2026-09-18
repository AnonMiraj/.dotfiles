# Per-monitor workspace sets, via the hyprsplit lua library.
#
# Hyprland has a single global workspace pool, so "workspace 1 on each monitor"
# is not expressible with plain config. hyprsplit is the purpose-built answer:
# it reserves a block of underlying workspace ids per monitor while presenting
# 1..num_workspaces on each one.
#
# Why this is low risk despite being a workspace rewrite:
#   - It is PURE LUA, not a C++ plugin. It only calls documented hl.* functions,
#     so there is no PLUGIN_API_VERSION handshake and nothing to crash the
#     compositor on a Hyprland update.
#   - Upstream requires Hyprland >= 0.55.0; this repo runs 0.56.2.
#   - hyprsplit.dsp.focus() returns a closure and resolves the active monitor
#     INSIDE it, i.e. at dispatch time. If it resolved at bind time every bind
#     would target whichever monitor happened to be focused at login.
#
# The C++ plugin of the same name (still what pkgs.hyprlandPlugins.hyprsplit
# builds) is deprecated upstream and deliberately not used.
{
  pkgs,
  lib,
  ...
}: let
  # Kanji numerals for the ten workspaces each monitor gets. Workspace 10 maps
  # to the `0` key, so the tenth label is 十 (ten).
  labels = ["一" "二" "三" "四" "五" "六" "七" "八" "九" "十"];

  # Same owner/repo/rev as nixpkgs' hyprlandPlugins.hyprsplit, so the hash is
  # reused rather than fetched blind.
  hyprsplit = pkgs.fetchFromGitHub {
    owner = "shezdy";
    repo = "hyprsplit";
    rev = "6b00b677d8905fb38779c91e12d6294e0e586a44";
    hash = "sha256-PaoUtmk+qIP/ESdxkxnY7mUMpMHjix88qu22R5GLQqE=";
  };
in {
  # Lands at ~/.config/hypr/hyprsplit/init.lua. Home Manager adds
  # $XDG_CONFIG_HOME/hypr/?/init.lua to package.path, so require("hyprsplit")
  # resolves without any path juggling.
  xdg.configFile."hypr/hyprsplit/init.lua".source = "${hyprsplit}/init.lua";

  # Home Manager emits extraLuaFiles requires BEFORE the settings block, so this
  # runs before the hl.bind() calls generated from binds.nix. `hs` is therefore
  # deliberately a global, not a local: a local would not be visible to those
  # later calls in the same generated chunk.
  wayland.windowManager.hyprland.extraLuaFiles."hyprsplit-init" = ''
    hs = require("hyprsplit")

    hs.config({
      num_workspaces = 10,
      -- True so all ten workspaces exist on each monitor. Without it workspaces
      -- only appear once used, so the bar would show just the ones in use rather
      -- than 一..十 on both monitors. This is what makes the labels visible.
      persistent_workspaces = true,
    })

    -- Order matters: the first monitor gets the lowest block. This hands
    -- underlying ids 1-10 to eDP-1 and 11-20 to HDMI-A-1, which is why window
    -- rules elsewhere can target "1" and "2" and land on eDP-1.
    hs.monitor_priority({ "eDP-1", "HDMI-A-1" })

    -- workspace_rule's default_name only takes effect when a workspace is
    -- CONSTRUCTED (see CWorkspace's constructor), so workspaces that already
    -- existed when the rule was added keep their numeric name. Re-apply on
    -- each reload, iterating real workspaces so absent ids are never touched.
    local LABELS = { ${lib.concatMapStringsSep ", " (l: "\"${l}\"") labels} }
    local function label_workspaces()
      for _, w in ipairs(hl.get_workspaces()) do
        local id = w.id
        if id and id >= 1 then
          -- works modulo the block size, so both monitors get the same ten
          local idx = ((id - 1) % 10) + 1
          hl.dispatch(hl.dsp.workspace.rename({ workspace = tostring(id), name = LABELS[idx] }))
        end
      end
    end
    hl.on("config.reloaded", label_workspaces)
    label_workspaces()
  '';

  # Label the reserved ids with kanji numerals so the workspace indicator reads
  # the same on both monitors. hyprsplit reserves global ids (1-10 for eDP-1,
  # 11-20 for HDMI-A-1) but the user-facing numbering is 1..10 per monitor, so
  # each block gets the same ten labels.
  #
  # `default_name` is the declarative way to do this - no runtime rename, and
  # it applies whenever a workspace is created. The duplicated labels are
  # display-only: nothing references these workspaces by name any more (the old
  # name:browser / name:chat selectors are gone), so there is no ambiguity to
  # resolve.
  #
  # Note this is cosmetic only. It does not change which ids hyprsplit uses.
  wayland.windowManager.hyprland.settings.workspace_rule =
    lib.concatMap (
      block:
        lib.imap0 (
          i: kanji: {
            workspace = toString (block * 10 + i + 1);
            default_name = kanji;
          }
        )
        labels
    )
    [0 1];
}
