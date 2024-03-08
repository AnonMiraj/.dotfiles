local M = {
   'nvim-telescope/telescope.nvim',
    version = false,
    cmd = "Telescope",
    dependencies = {
	{'nvim-lua/plenary.nvim'},
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
        {'nvim-telescope/telescope-fzf-native.nvim',},
    },
}

function M.init()
	-- See `:help telescope.builtin`
	vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = 'Find files' })
	vim.keymap.set('n', '<leader>fa', "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", { desc = 'Find All' })
	vim.keymap.set('n', '<leader>fo', require('telescope.builtin').oldfiles, { desc = 'Find oldfiles' })
	vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers, { desc = 'Find buffers' })
	vim.keymap.set('n', '<leader>f/', function()
	  -- You can pass additional configuration to telescope to change theme, layout, etc.
	  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
	    winblend = 10,
	    previewer = false,
	  })
	end, { desc = 'Fuzzily search in current buffer' })

	vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = 'Help page' })
	vim.keymap.set('n', '<leader>fg', require('telescope.builtin').git_files, { desc = 'Find Git Files' })
	vim.keymap.set('n', '<leader>fc', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
	vim.keymap.set('n', '<leader>fw', require('telescope.builtin').live_grep, { desc = 'Live grep' })
	vim.keymap.set('n', '<leader>fd', require('telescope.builtin').diagnostics, { desc = 'Find [D]iagnostics' })
	vim.keymap.set('n', '<leader>th', require('telescope.builtin').colorscheme, { desc = 'Preview Colorscheme' })


end
function M.config()
	require('telescope').setup {
	  defaults = {
          vimgrep_arguments = {
      "rg",
      "-L",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
    },
	  },
      pickers = {
    colorscheme = {
      enable_preview = true
    }
  }
	}
end

return M
