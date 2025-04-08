return {
    "benlubas/molten-nvim",
    version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
    dependencies = { "quarto-dev/quarto-nvim", "3rd/image.nvim", "GCBallesteros/jupytext.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
        vim.g.molten_output_win_max_height = 20
        vim.g.molten_auto_open_output = false
        vim.g.molten_image_provider = "image.nvim"
        vim.g.molten_wrap_output = true
        vim.g.molten_virt_text_output = true
        vim.g.molten_virt_lines_off_by_1 = true
    end,
    lazy = false,
    config = function()
        vim.keymap.set("n", "<localleader>e", ":MoltenEvaluateOperator<CR>",
            { desc = "Evaluate operator", silent = true })
        vim.keymap.set("n", "<localleader>os", ":noautocmd MoltenEnterOutput<CR>",
            { desc = "Open output window", silent = true })
    end,

    require("jupytext").setup({
        style = "markdown",
        output_extension = "md",
        force_ft = "markdown",
    }),
    require("nvim-treesitter.configs").setup({
        -- ... other ts config
        textobjects = {
            move = {
                enable = true,
                set_jumps = false, -- you can change this if you want.
                goto_next_start = {
                    --- ... other keymaps
                    ["]b"] = { query = "@code_cell.inner", desc = "next code block" },
                },
                goto_previous_start = {
                    --- ... other keymaps
                    ["[b"] = { query = "@code_cell.inner", desc = "previous code block" },
                },
            },
            select = {
                enable = true,
                lookahead = true, -- you can change this if you want
                keymaps = {
                    --- ... other keymaps
                    ["ib"] = { query = "@code_cell.inner", desc = "in block" },
                    ["ab"] = { query = "@code_cell.outer", desc = "around block" },
                },
            },
            swap = { -- Swap only works with code blocks that are under the same
                -- markdown header
                enable = true,
                swap_next = {
                    --- ... other keymap
                    ["<leader>sbl"] = "@code_cell.outer",
                },
                swap_previous = {
                    --- ... other keymap
                    ["<leader>sbh"] = "@code_cell.outer",
                },
            },
        }
    })
    --
    --
}
