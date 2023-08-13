return {
  {
    "abecodes/tabout.nvim",
    --Supercharge your workflow and start tabbing out from parentheses, quotes, and similar contexts today.
    event = "BufEnter",
    config = function()
      require('tabout').setup {
        tabkey = '<Tab>',             -- key to trigger tabout, set to an empty string to disable
        backwards_tabkey = '<S-Tab>', -- key to trigger backwards tabout, set to an empty string to disable
        act_as_tab = true,            -- shift content if tab out is not possible
        act_as_shift_tab = false,     -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
        default_tab = '<C-t>',        -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
        default_shift_tab = '<C-d>',  -- reverse shift default action,
        enable_backwards = true,      -- well ...
        completion = true,            -- if the tabkey is used in a completion pum
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = '`', close = '`' },
          { open = '(', close = ')' },
          { open = '[', close = ']' },
          { open = '{', close = '}' },
          { open = '<', close = '>' }
        },
        ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
        exclude = {} -- tabout will ignore these filetypes
      }
    end,
  },

  {
    "max397574/better-escape.nvim",
    --Escape from insert mode without delay when typing
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    "m-demare/hlargs.nvim",
    --Highlight arguments' definitions and usages, asynchronously, using Treesitter
    event = "BufWinEnter",
    config = function()
      require("hlargs").setup()
    end,
  },

  {
    --nvim-hlslens helps you better glance at matched information, seamlessly jump between matched instances.
    --(numbers after search)
    "kevinhwang91/nvim-hlslens",
    event = "BufReadPost",
    config = function()
      require("hlslens").setup()
    end,
  },


  {
    "mrjones2014/nvim-ts-rainbow",
    -- Rainbow delimiters {[()]} for Neovim through Tree-sitter
    event = "BufReadPost",
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
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
        throttle = true, -- Throttles plugin updates (may improve performance)
        max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
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


}
