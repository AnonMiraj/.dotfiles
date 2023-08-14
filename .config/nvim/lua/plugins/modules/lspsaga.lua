local M = {
  'nvimdev/lspsaga.nvim',
  event = "LspAttach",
  -- config = function()
  -- require "custom.configs.external.lspsaga"
  -- end,
  dependencies = {
    'nvim-treesitter/nvim-treesitter',     -- optional
    'nvim-tree/nvim-web-devicons'          -- optional
  }
}

function M.init()
  vim.keymap.set('n', '[d', '<cmd>Lspsaga  diagnostic_jump_prev <CR>', { desc = "Goto prev" })
  vim.keymap.set('n', ']d', '<cmd>Lspsaga  diagnostic_jump_next <CR>', { desc = "Goto next" })
  vim.keymap.set('n', '<leader>dd', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })
  vim.keymap.set( 'n','K', '<cmd>Lspsaga hover_doc <CR>',  { desc = "Hover Documentation"} )
  vim.keymap.set('n', '<leader>ca', '<cmd>Lspsaga code_action <CR>', { desc = '[C]ode [A]ction' })
  vim.keymap.set('n', 'gd', '<cmd>Lspsaga  goto_definition <CR>', { desc = "LSP definition" })
  vim.keymap.set('n', '<leader>ra', '<cmd>Lspsaga  rename <CR>', { desc = "LSP rename" })
end

function M.config()
  local present, lspsaga = pcall(require, "lspsaga")

  if not present then
    return
  end
  lspsaga.setup {
    preview = {
      lines_above = 0,
      lines_below = 10,
    },
    -- scroll_preview = {
    --   scroll_down = "<C-f>",
    --   scroll_up = "<C-b>",
    -- },
    -- definition = {
    --   edit = "<C-c>o",
    --   vsplit = "<C-c>v",
    --   split = "<C-c>i",
    --   tabe = "<C-c>t",
    --   quit = "q",
    --   close = "<Esc>",
    -- },
    code_action = {
      num_shortcut = true,
      keys = {
        -- string |table type
        quit = "<ESC>",
        exec = "<CR>",
      },
    },
    request_timeout = 2000,
    finder = {
      edit = { "o", "<CR>" },
      vsplit = "s",
      split = "i",
      tabe = "t",
      quit = { "q", "<ESC>" },
    },
    lightbulb = {
      enable = false,
      enable_in_insert = true,
      sign = true,
      sign_priority = 40,
      virtual_text = true,
    },
    diagnostic = {
      show_code_action = true,
      show_source = true,
      jump_num_shortcut = true,
      keys = {
        exec_action = "o",
        quit = "q",
        go_action = "g",
      },
      theme = {},
    },
    outline = {
      win_position = "right",
      win_with = "",
      win_width = 30,
      show_detail = true,
      auto_preview = true,
      auto_refresh = true,
      auto_close = true,
      custom_sort = nil,
      keys = {
        jump = "o",
        expand_collapse = "u",
        quit = "q",
      },
    },
    symbol_in_winbar = {
      enable = true,
      separator = " ",
      hide_keyword = true,
      show_file = true,
      folder_level = 2,
      respect_root = false,
      color_mode = true,
    },
    ui = {
      -- currently only round theme
      theme = "round",
      -- this option only work in neovim 0.9
      title = true,
      -- border type can be single,double,rounded,solid,shadow.
      border = "rounded",
      winblend = 0,
      expand = "",
      collapse = "",
      preview = " ",
      code_action = "💡",
      diagnostic = "🐞",
      incoming = " ",
      outgoing = " ",
      colors = {
        --float window normal background color
        normal_bg = "#000000",
        --title background color
        title_bg = "#FF7070",
        red = "#e95678",
        magenta = "#b33076",
        orange = "#FF8700",
        yellow = "#f7bb3b",
        green = "#afd700",
        cyan = "#36d0e0",
        blue = "#61afef",
        purple = "#CBA6F7",
        white = "#d1d4cf",
        black = "#1c1c19",
      },
      kind = { ["Folder"] = { "  ", "@comment" } },
    },
  }
        local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end
end

return M
