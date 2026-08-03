{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.nvf.settings.vim = {
    # ── LSP + extras ──────────────────────────────────────────────
    lsp = {
      enable = true;
      lspconfig.enable = true;
      presets.clangd.enable = true;
      lightbulb.enable = true;

      mappings = {
        goToDefinition = "gd";
        hover = "K";
        listReferences = "gr";
        codeAction = "<leader>ca";
        renameSymbol = "<leader>rn";
        nextDiagnostic = "]d";
        previousDiagnostic = "[d";
        format = "<leader>lf";
      };

      trouble = {
        enable = true;
        mappings = {
          workspaceDiagnostics = "<leader>xX";
          documentDiagnostics = "<leader>xx";
          lspReferences = "<leader>cl";
          quickfix = "<leader>xQ";
          locList = "<leader>xL";
          symbols = "<leader>cs";
        };
      };
    };

    # ── Treesitter ────────────────────────────────────────────────
    treesitter = {
      enable = true;
      highlight.enable = true;
      textobjects = {
        enable = true;
        setupOpts = {
          select = {
            enable = true;
            lookahead = true;
            keymaps = {
              af = "@function.outer";
              "if" = "@function.inner";
              ac = "@class.outer";
              ic = "@class.inner";
            };
          };
        };
      };
    };

    # ── Autocomplete ─────────────────────────────────────────────
    autocomplete.nvim-cmp.enable = true;

    # ── Statusline ────────────────────────────────────────────────
    statusline.lualine.enable = true;

    # ── Git ───────────────────────────────────────────────────────
    git = {
      enable = true;
      gitsigns.enable = true;
    };

    # ── Comments ──────────────────────────────────────────────────
    comments.comment-nvim.enable = true;

    # ── Snippets ──────────────────────────────────────────────────
    snippets.luasnip.enable = true;

    # ── Utility plugins ───────────────────────────────────────────
    utility = {
      sleuth.enable = true;
      oil-nvim.enable = true;
      csvview.enable = true;
      # images.image-nvim.enable = true;
      motion.leap.enable = true;
    };

    # ── Visual / UI plugins ───────────────────────────────────────
    visuals.fidget-nvim.enable = true;
    ui = {
      nvim-highlight-colors.enable = true;
      smartcolumn = {
        enable = true;
        setupOpts.colorcolumn = "80";
      };
      illuminate.enable = true;
    };
  };
}
