{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.nvf.settings.vim = {
    # ── Core editor options ──────────────────────────────────────
    lineNumberMode = "relNumber";
    hideSearchHighlight = true;
    preventJunkFiles = true;
    undoFile.enable = true;
    searchCase = "smart";

    # ── Clipboard (system + primary) ─────────────────────────────
    clipboard = {
      enable = true;
      registers = "unnamed,unnamedplus";
    };

    # ── Theme ─────────────────────────────────────────────────────
    # Disabled — alabaster.nvim handles it via extraPlugins
    theme.enable = false;
  };
}
