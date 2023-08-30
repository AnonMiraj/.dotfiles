-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- NOTE: First, some plugins that don't require any configuration

  -- Git related plugins
  { 'tpope/vim-fugitive', cmd = "Git" },
  { 'tpope/vim-rhubarb',  cmd = "HBrowse" },

  -- Detect tabstop and shiftwidth automatically
  { 'tpope/vim-sleuth',   event = "BufRead" },

  -- Useful plugin to show you pending keybinds.
  {
    'folke/which-key.nvim',

    lazy = false,
    opts = {}
  },
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    ft = { "gitcommit", "diff" },
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>gp', require('gitsigns').prev_hunk,
          { buffer = bufnr, desc = '[G]o to [P]revious Hunk' })
        vim.keymap.set('n', '<leader>gn', require('gitsigns').next_hunk, { buffer = bufnr, desc = '[G]o to [N]ext Hunk' })
        vim.keymap.set('n', '<leader>ph', require('gitsigns').preview_hunk, { buffer = bufnr, desc = '[P]review [H]unk' })
      end,
    },
  },


  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    lazy = false,
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = true,
        component_separators = '|',
        section_separators = '',
      },
    },
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    event = "BufRead",
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help indent_blankline.txt`
    opts = {
      char = '┊',
      show_trailing_blankline_indent = false,
      show_current_context = true,
      show_current_context_start = true,
    },
  },

  -- "gc" to comment visual regions/lines
  {
    'numToStr/Comment.nvim',

    event = "BufRead",
    opts = {}
  },
 
  {
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    config = function()
      vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
    end
  },
  {
    "alec-gibson/nvim-tetris",
    cmd = { "Tetris" },
  },

  {
    'iamcco/markdown-preview.nvim',
    build = function() vim.fn['mkdp#util#install']() end,
    config = function() vim.g.mkdp_filetypes = { 'markdown' } end,
    ft = { 'markdown' },
    keys = {
      { '<leader>P', '<Plug>MarkdownPreviewToggle', desc = '[P]review markdown in the browser' }
    }
  },


  --themes
  { "sainnhe/gruvbox-material", lazy = false, priority = 1000 },
  { "folke/tokyonight.nvim",    lazy = false, priority = 1000 },
  { "adigitoleo/vim-mellow",    lazy = false, priority = 1000 },
  { "rose-pine/neovim",    lazy = false, priority = 1000 },
  { "catppuccin/nvim",    lazy = false, priority = 1000 },
  { "ivanhernandez/pompeii",    lazy = false, priority = 1000 },
  { "tobi-wan-kenobi/zengarden",    lazy = false, priority = 1000 },
  { "maxmx03/solarized.nvim",    lazy = false, priority = 1000 },
  { "sainnhe/everforest",    lazy = false, priority = 1000 },
  { "olimorris/onedarkpro.nvim",    lazy = false, priority = 1000 },
  { "rebelot/kanagawa.nvim",    lazy = false, priority = 1000 },
  { "rafi/awesome-vim-colorschemes",    lazy = false, priority = 1000 },
  { "savq/melange-nvim",    lazy = false, priority = 1000 },
  { "nlknguyen/papercolor-theme",    lazy = false, priority = 1000 },
  { "sainnhe/edge",    lazy = false, priority = 1000 },
  { "mofiqul/vscode.nvim",    lazy = false, priority = 1000 },

}
