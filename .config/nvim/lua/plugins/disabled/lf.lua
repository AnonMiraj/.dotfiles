local M = {
    "lmburns/lf.nvim",
    version = false,
    lazy = false,
    dependencies = {
	'akinsho/toggleterm.nvim', version = "*", config = true
    },
  enabled=false
}

function M.config()
        -- This feature will not work if the plugin is lazy-loaded
        vim.g.lf_netrw = 1
        require("lf").setup({
            -- escape_quit = false,
            border = "rounded",
        })

        vim.keymap.set("n", "<C-e>", "<Cmd>Lf<CR>",{ desc = 'Open Lf' })
        -- vim.api.nvim_create_autocmd({
        --     event = "User",
        --     pattern = "LfTermEnter",
        --     callback = function(a)
        --         vim.api.nvim_buf_set_keymap(a.buf, "t", "q", "q", {nowait = true})
        --     end,
        -- })



end

return M
