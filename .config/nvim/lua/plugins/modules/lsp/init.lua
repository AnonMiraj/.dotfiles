return {
  -- LSP Configuration & Plugins
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    -- Automatically install LSPs to stdpath for neovim
    { 'williamboman/mason.nvim', config = true },
    'williamboman/mason-lspconfig.nvim',

    -- Useful status updates for LSP
    { 'j-hui/fidget.nvim', opts = {} },

    -- New replacement for neodev: provides lsp stuff for neovim config
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          -- Load luvit types when the `vim.uv` word is found
          { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        },
      },
    },
    -- Optional: for lazydev types
    { 'Bilal2453/luvit-meta', lazy = true },
  },
  config = function()
    -- This calls the file where the actual LSP settings live
    require "plugins.modules.lsp.config"
  end,
}
