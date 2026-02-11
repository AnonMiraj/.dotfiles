local M = {
	'nvim-telescope/telescope.nvim',
	version = false,
	cmd = "Telescope",
	dependencies = {
		{ 'nvim-lua/plenary.nvim' },
		-- Fuzzy Finder Algorithm which requires local dependencies to be built.
		-- Only load if `make` is available. Make sure you have the system
		-- requirements installed.
		{ 'nvim-telescope/telescope-fzf-native.nvim', },
	},
}

function M.init()
	-- See `:help telescope.builtin`
	vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = 'Find files' })
	vim.keymap.set('n', '<leader>fa', "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>",
		{ desc = 'Find All' })
	vim.keymap.set('n', '<leader>fo', require('telescope.builtin').oldfiles, { desc = 'Find oldfiles' })
	vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = 'Help page' })

	vim.keymap.set('n', '<leader>fw', function()
		local dir = vim.fn.expand('%:p:h')
		if dir == '' then
			dir = vim.loop.cwd()
		end

		require('telescope.builtin').live_grep({ cwd = dir })
	end, { desc = 'Live grep (file dir)' })
	vim.keymap.set('n', '<leader>fW', require('telescope.builtin').live_grep, { desc = 'Live grep' })
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
