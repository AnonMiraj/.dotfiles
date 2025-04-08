-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- NOTE: First, some plugins that don't require any configuration


  -- Detect tabstop and shiftwidth automatically
  { 'tpope/vim-sleuth',              event = "BufRead" },
  --
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

  -- {
  --   -- Add indentation guides even on blank lines
  --   'lukas-reineke/indent-blankline.nvim',
  --   event = "BufRead",
  --   -- Enable `lukas-reineke/indent-blankline.nvim`
  --   -- See `:help indent_blankline.txt`
  --   opts = {
  --     char = '┊',
  --     show_trailing_blankline_indent = false,
  --     show_current_context = true,
  --     show_current_context_start = true,
  --   },
  -- },
  --
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
    end,
    keys = {
      { '<C-u>', '<Plug>UndotreeToggle', desc = "Undotree Toggle" }
    }

  },
  {
    "alec-gibson/nvim-tetris",
    cmd = { "Tetris" },
  },

  {
    "NStefan002/speedtyper.nvim",
    cmd = "Speedtyper",
  },

  {
    "Pocco81/auto-save.nvim",
    event = "BufRead",
    config = function()
      require("auto-save").setup()
    end,
    vim.api.nvim_set_keymap("n", "<leader>n", ":ASToggle<CR>", {})
  },


  { 'norcalli/nvim-colorizer.lua',   ft = { "scss", "css" } },
  --themes
  { "sainnhe/gruvbox-material",      lazy = false,          priority = 1000 },
  { "folke/tokyonight.nvim",         lazy = false,          priority = 1000 },
  { "adigitoleo/vim-mellow",         lazy = false,          priority = 1000 },
  { "rose-pine/neovim",              lazy = false,          priority = 1000 },
  { "catppuccin/nvim",               lazy = false,          priority = 1000 },
  { "ivanhernandez/pompeii",         lazy = false,          priority = 1000 },
  { "tobi-wan-kenobi/zengarden",     lazy = false,          priority = 1000 },
  { "maxmx03/solarized.nvim",        lazy = false,          priority = 1000 },
  { "sainnhe/everforest",            lazy = false,          priority = 1000 },
  { "olimorris/onedarkpro.nvim",     lazy = false,          priority = 1000 },
  { "rebelot/kanagawa.nvim",         lazy = false,          priority = 1000 },
  { "rafi/awesome-vim-colorschemes", lazy = false,          priority = 1000 },
  { "savq/melange-nvim",             lazy = false,          priority = 1000 },
  { "nlknguyen/papercolor-theme",    lazy = false,          priority = 1000 },
  { "sainnhe/edge",                  lazy = false,          priority = 1000 },
  { "mofiqul/vscode.nvim",           lazy = false,          priority = 1000 },
  { "uZer/pywal16.nvim",             lazy = false,          priority = 1000 },
  {
    "oncomouse/lushwal.nvim",
    cmd = { "LushwalCompile" },
    dependencies = {
      { "rktjmp/lush.nvim" },
      { "rktjmp/shipwright.nvim" },
    },
  },


  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_browser = "/sbin/zen-browser"
    end,
    ft = { "markdown" },
  },

  {
    'barrett-ruth/live-server.nvim',
    build = 'pnpm add -g live-server',
    cmd = { 'LiveServerStart', 'LiveServerStop' },
    config = true
  },
  {
    "lambdalisue/vim-suda",
    cmd = { 'SudaWrite', 'SudaRead' },
  },
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts

    cmd = { 'Oil' },
    opts = {},
    -- Optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  },
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre path/to/my-vault/*.md",
    --   "BufNewFile path/to/my-vault/*.md",
    -- },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",

      -- see below for full list of optional dependencies 👇
    },
    opts = {

      disable_frontmatter = true,
      workspaces = {
        {
          name = "personal",
          path = "~/vaults/personal",
        },
        {
          name = "work",
          path = "/home/nir/Documents/schloars",
        },
      },

      -- see below for full list of options 👇
    }
  },
  {
    "nvzone/typr",
    dependencies = "nvzone/volt",
    opts = {},
    cmd = { "Typr", "TyprStats" },

  },
  {
    'IogaMaster/neocord',
    event = "VeryLazy"
  }
}
