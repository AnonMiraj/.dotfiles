local M = {
  "jinzhongjia/LspUI.nvim",
  lazy = false,
  branch = "main",
  config = function()
    require("LspUI").setup({
      -- config options go here
    })
  end
}

-- Keybindings to be set globally or on attach
function M.init()
  -- These can be called here if you want them set globally,
  -- or inside the LspAttach autocommand in config.lua
  local nmap = function(keys, func, desc)
    vim.keymap.set('n', keys, func, { desc = 'LSP UI: ' .. desc })
  end

  nmap('gd', '<cmd>LspUI definition<CR>', 'Goto Definition')
  nmap('gr', '<cmd>LspUI reference<CR>', 'Find References')
  nmap('gi', '<cmd>LspUI implementation<CR>', 'Goto Implementation')
  nmap('gt', '<cmd>LspUI type_definition<CR>', 'Type Definition')
  nmap('<leader>ca', '<cmd>LspUI code_action<CR>', 'Code Action')
  nmap('<leader>rn', '<cmd>LspUI rename<CR>', 'Rename Symbol')
  nmap('K', '<cmd>LspUI hover<CR>', 'Hover Documentation')

  -- Diagnostic Navigation via LspUI
  nmap(']d', '<cmd>LspUI diagnostic next<CR>', 'Next Diagnostic')
  nmap('[d', '<cmd>LspUI diagnostic prev<CR>', 'Prev Diagnostic')
end

function M.config()
  local status_ok, LspUI = pcall(require, "LspUI")
  if not status_ok then
    return
  end

  LspUI.setup({
    -- Rename configuration
    rename = {
      enable = true,
      command_enable = true,
      auto_select = true,
      border = "rounded",
    },

    -- Code Action configuration
    code_action = {
      enable = true,
      command_enable = true,
      gitsigns = true,
      key_binding = {
        exec = "<CR>",
        prev = "k",
        next = "j",
        quit = "q",
      },
      border = "rounded",
    },
    signature = {
      enable = false,
      icon = "✨",
      color = {
        fg = "#FF8C00",
        bg = nil,
      },
      debounce = 300,
    },

    -- Hover configuration
    hover = {
      enable = true,
      command_enable = true,
      key_binding = {
        prev = "p",
        next = "n",
        quit = "q",
      },
      border = "rounded",
    },

    -- Diagnostic configuration
    diagnostic = {
      enable = true,
      command_enable = true,
      border = "rounded",
      show_source = true,
      show_code = true,
      max_width = 0.6,
    },

    -- Lightbulb configuration (shows when code actions available)
    lightbulb = {
      enable = false,
      icon = "💡",
      debounce = 250,
    },

    -- Inlay Hint configuration
    inlay_hint = {
      enable = true,
      command_enable = true,
    },

    -- Jump History
    jump_history = {
      enable = true,
      command_enable = true,
      max_size = 50,
    },

    -- Global UI styles
    pos_keybind = {
      secondary = {
        jump = "o",
        jump_split = "sh",
        jump_vsplit = "sv",
        quit = "q",
      },
      main_border = "rounded",
      secondary_border = "rounded",
    },
  })
end

return M
