return {

  {
    --nvim-hlslens helps you better glance at matched information, seamlessly jump between matched instances.
    --(numbers after search)
    "kevinhwang91/nvim-hlslens",
    lazy = false,
    config = function()
      require('hlslens').setup()

      local kopts = { noremap = true, silent = true }

      vim.api.nvim_set_keymap('n', 'n',
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', 'N',
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)

      vim.api.nvim_set_keymap('n', '<Leader>l', '<Cmd>noh<CR>', kopts)
    end,
  },


  {
    "nvim-treesitter/nvim-treesitter-context",
    -- shows the context of the currently visible buffer contents
    event = "BufWinEnter",
    config = function()
      local present, context = pcall(require, "treesitter-context")

      if not present then
        return
      end

      require("treesitter-context").setup {
        enable = true,   -- Enable this plugin (Can be enabled/disabled later via commands)
        throttle = true, -- Throttles plugin updates (may improve performance)
        max_lines = 0,   -- How many lines the window should span. Values <= 0 mean no limit.
        patterns = {
          default = {
            "class",
            "function",
            "method",
          },
        },
      }
    end,
  },
  {
    "ethanholz/nvim-lastplace",
    -- Intelligently reopen files at your last edit position.
    event = "BufReadPost",
    config = function()
      require("nvim-lastplace").setup {
        lastplace_ignore_buftype = {
          "terminal",
          "help",
          "Trouble",
        },
        lastplace_ignore_filetype = {
          "terminal",
          "help",
          "Trouble",
        },
        lastplace_open_folds = true,
      }
    end,
    -- lazy = false,
  },
  --

}
