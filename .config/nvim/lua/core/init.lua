--require("core.lazy")
require("core.globals")
require("core.settings")
require("core.idk")
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

