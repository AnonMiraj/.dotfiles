local M = {
  "ray-x/navigator.lua",
  dependencies = {
    "ray-x/guihua.lua", -- required
    "neovim/nvim-lspconfig",
    "nvim-tree/nvim-web-devicons"
  },
  lazy = false,
}

function M.init()
  -- LSP-like keymaps similar to your old Lspsaga ones
  vim.keymap.set('n', 'gd', '<cmd>lua require("navigator.definition").definition()<CR>', { desc = "Goto Definition" })
  vim.keymap.set('n', 'gr', '<cmd>lua require("navigator.reference").reference()<CR>', { desc = "Find References" })
  vim.keymap.set('n', '<leader>ca', '<cmd>lua require("navigator.codeAction").code_action()<CR>',
    { desc = "Code Action" })
  vim.keymap.set('n', '<leader>rn', '<cmd>lua require("navigator.rename").rename()<CR>', { desc = "Rename Symbol" })
  vim.keymap.set('n', 'K', '<cmd>lua require("navigator.hover").hover()<CR>', { desc = "Hover Documentation" })
  --
  vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', { desc = "Next Diagnostic" })
  vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', { desc = "Prev Diagnostic" })
  vim.keymap.set('n', '<leader>dd', '<cmd>lua vim.diagnostic.setloclist()<CR>', { desc = "Open Diagnostics List" })
end

function M.config()
  local ok, navigator = pcall(require, "navigator")
  if not ok then
    return
  end

  navigator.setup({
    mason = true,            -- automatically configure LSPs if using mason
    default_mapping = false, -- we’ll use our own keymaps
    transparency = 0,
    lsp = {
      code_action = { enable = true, sign = true, virtual_text = true },
      format_on_save = false,
      disable_lsp = {}, -- list of LSPs to skip
    },


    ts_fold = {
      enable = true,
      max_lines_scan_comments = 20,                     -- only fold when the fold level higher than this value
      disable_filetypes = { 'help', 'guihua', 'text' }, -- list of filetypes which doesn't fold using treesitter
    },

  })

  -- Custom diagnostic signs
  local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
  end
end

return M
