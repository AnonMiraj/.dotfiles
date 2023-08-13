local M =
  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
     event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      {
            "simrat39/symbols-outline.nvim",
            config = function()
                require("symbols-outline").setup {}
            end,
      }
    },
    build = ':TSUpdate',
  }
  -- ensure_installed = { "lua" },
  --
  -- highlight = {
  --   enable = true,
  --   use_languagetree = true,
  -- },
  --
  -- indent = { enable = true },
  --
function M.config()
    local treesitter = require "nvim-treesitter.configs"
    treesitter.setup {
        ensure_installed = {"rust","lua","cpp","markdown","markdown_inline"},
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
            use_languagetree = true,
        },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "gnn",
                node_umental = "gnn",
                scope_incremental = "gns",
                node_decremental = "gnp",
            },
        },
        context_commentstring = {
            enable = true,
        },
        textobjects = {
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["ic"] = "@class.inner",
                    ["iB"] = "@block.inner",
                    ["aB"] = "@block.outer",
                    ["iF"] = "@frame.inner",
                    ["aF"] = "@frame.outer",
                },
            },
            swap = {
                enable = true,
                disable = { "lua" },
                swap_next = {
                    ["<leader>a"] = "@parameter.inner",
                },
                swap_previous = {
                    ["<leader>A"] = "@parameter.inner",
                },
            },
            move = {
                enable = true,
                set_jumps = true,
                goto_next_start = {
                    ["]]"] = "@function.outer",
                },
                goto_next_end = {
                    ["]["] = "@function.outer",
                },
                goto_previous_start = {
                    ["[["] = "@function.outer",
                },
                goto_previous_end = {
                    ["[]"] = "@function.outer",
                },
            },
        },
    }
end


return M
