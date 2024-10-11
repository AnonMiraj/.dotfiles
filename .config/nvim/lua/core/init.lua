--require("core.lazy")
require("core.globals")
require("core.settings")
--require("core.remap")
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        require "core.mappings"
    end,
})
