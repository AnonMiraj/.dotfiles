# Per-monitor workspace sets, via the hyprsplit lua library.
#
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
  xdg.configFile."hypr/hyprsplit/init.lua".source = "${hyprsplit}/init.lua";

  wayland.windowManager.hyprland.extraLuaFiles."hyprsplit-init" = ''
    hs = require("hyprsplit")

    hs.config({
      num_workspaces = 10,
      persistent_workspaces = true,
    })

    hs.monitor_priority({ "eDP-1", "HDMI-A-1" })

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
