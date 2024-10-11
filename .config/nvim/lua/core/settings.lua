local M = {}

function M.setup()
  M.globals()
  M.options()
  M.commands()
end

function M.globals()
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

end

function M.options()
  -- Make line numbers default
  vim.wo.number = true
  vim.opt.relativenumber = true

  -- Enable mouse mode
  vim.o.mouse = 'a'

  -- Sync clipboard between OS and Neovim.
  vim.o.clipboard = 'unnamedplus'

  -- Enable break indent
  vim.o.breakindent = true

  -- Save undo history
  vim.o.undofile = true

  -- Case-insensitive searching UNLESS \C or capital in search
  vim.o.ignorecase = true
  vim.o.smartcase = true

  vim.opt.hlsearch = false
  vim.opt.incsearch = true

  -- Decrease update time
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300

  -- Set completeopt to have a better completion experience
  vim.o.completeopt = 'menuone,noselect'

  -- vim.o.wrap = false

  vim.o.termguicolors = true

  -- Indenting
  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.smartindent = true
  vim.opt.tabstop = 2
  vim.opt.softtabstop = 2

  vim.opt.backup = false
  vim.opt.swapfile = false

  vim.opt.encoding = "utf-8"
  vim.opt.fileencoding = "utf-8"
  vim.opt.wrap = false
  vim.o.spelllang = "en_us"

  vim.opt.foldcolumn = "2"
  vim.opt.foldlevel = 1
  vim.opt.foldnestmax = 2
  vim.opt.foldlevelstart = 99
  vim.opt.foldenable = true
  vim.opt.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
  vim.opt.signcolumn = "auto:1-2"
  -- Line breaks
  vim.opt.linebreak = true    -- Wrap long lines at word boundaries
  vim.opt.showbreak = '+'     -- Gutter string before wrapped lines
  vim.opt.whichwrap = 'b,s,h,l' -- Keys allowed to move across lines

  -- [[ Highlight on yank ]]
  -- See `:help vim.highlight.on_yank()`
  local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
  vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
      vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = '*',
  })
  vim.o.background = "light"
end

function M.commands()

end

M.setup()
