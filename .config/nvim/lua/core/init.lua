--require("core.lazy")
require("core.globals")
require("core.settings")
-- require("core.idk")
--require("core.remap")
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    require "core.mappings"
  end,
})
vim.fn.expand "~"
local vault_location = "/home/nir/Documents/schloars" .. "/**.md"
local group = vim.api.nvim_create_augroup("obsidian_cmds", { clear = true })
vim.api.nvim_create_autocmd("BufAdd", {
  command = "ObsidianOpen",
  pattern = { vault_location },
  group = group,
  desc = "Opens the current buffer in Obsidian",
})


require("core.f16_libc")

local float16 = require("core.f16_libc")

-- Setup with custom config (optional)
float16.setup({
  highlight_group = "DiagnosticInfo",
  show_detailed_breakdown = false,
  format_precision = 8,
})

-- Initialize commands
float16.init()

-- Optional keybindings
vim.keymap.set('n', '<leader>ll', float16.toggle, { desc = 'Toggle float16 viewer' })
vim.keymap.set('n', '<leader>la', float16.toggle_auto_update, { desc = 'Toggle auto-update' })
vim.keymap.set('n', '<leader>lc', float16.convert_and_copy, { desc = 'Convert and copy' })
