return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",   -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
  },
  keys = {
    { "<c-e>", ":Neotree toggle<cr>", desc = "NeoTree" },
  },
  opts = {
    reveal = true,
    window = {
      width = 25,
      mappings = {
        ['Y'] = function(state)
          -- NeoTree is based on [NuiTree](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree)
          -- The node is based on [NuiNode](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree#nuitreenode)
          local node = state.tree:get_node()
          local filepath = node:get_id()
          local filename = node.name
          local modify = vim.fn.fnamemodify

          local results = {
            filepath,
            modify(filepath, ':.'),
            modify(filepath, ':~'),
            filename,
            modify(filename, ':r'),
            modify(filename, ':e'),
          }

          -- absolute path to clipboard
          local i = vim.fn.inputlist({
            'Choose to copy to clipboard:',
            '1. Absolute path: ' .. results[1],
            '2. Path relative to CWD: ' .. results[2],
            '3. Path relative to HOME: ' .. results[3],
            '4. Filename: ' .. results[4],
            '5. Filename without extension: ' .. results[5],
            '6. Extension of the filename: ' .. results[6],
          })

          if i > 0 then
            local result = results[i]
            if not result then return print('Invalid choice: ' .. i) end
            vim.fn.setreg('"', result)
          end
        end
      }
    },
    filesystem = {
      follow_current_file = { enabled = true }
    },
    source_selector = {
      winbar = true,
      statusline = true
    },
  },
}
