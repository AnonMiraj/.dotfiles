-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
	-- NOTE: First, some plugins that don't require any configuration

	-- Detect tabstop and shiftwidth automatically
	{ "tpope/vim-sleuth", event = "BufRead" },
	--
	-- Useful plugin to show you pending keybinds.
	{
		"folke/which-key.nvim",
		lazy = false,
		opts = {},
	},
	{
		-- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		ft = { "gitcommit", "diff" },
		lazy = false,
		opts = {
			-- See `:help gitsigns.txt`
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				vim.keymap.set(
					"n",
					"<leader>gp",
					require("gitsigns").prev_hunk,
					{ buffer = bufnr, desc = "[G]o to [P]revious Hunk" }
				)
				vim.keymap.set(
					"n",
					"<leader>gn",
					require("gitsigns").next_hunk,
					{ buffer = bufnr, desc = "[G]o to [N]ext Hunk" }
				)
				vim.keymap.set(
					"n",
					"<leader>ph",
					require("gitsigns").preview_hunk,
					{ buffer = bufnr, desc = "[P]review [H]unk" }
				)
			end,
		},
	},

	{
		-- Set lualine as statusline
		"nvim-lualine/lualine.nvim",
		lazy = false,
		-- See `:help lualine.txt`
		opts = {
			options = {
				icons_enabled = true,
				component_separators = "|",
				section_separators = "",
			},
		},
	},

	-- "gc" to comment visual regions/lines
	{
		"numToStr/Comment.nvim",

		event = "BufRead",
		opts = {},
	},

	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
		config = function()
			vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
		end,
		keys = {
			{ "<C-u>", "<Plug>UndotreeToggle", desc = "Undotree Toggle" },
		},
	},
	-- {
	--   "okuuva/auto-save.nvim",
	--   event = "BufRead",
	--   config = function()
	--     local nvim_config = vim.fn.stdpath("config")
	--
	--     require("auto-save").setup({
	--       condition = function(buf)
	--         local fname = vim.api.nvim_buf_get_name(buf)
	--         if fname:find(nvim_config, 1, true) then
	--           return false
	--         end
	--         return true
	--       end,
	--     })
	--   end,
	--   vim.api.nvim_set_keymap("n", "<leader>n", ":ASToggle<CR>", {})
	-- },

	--themes
	{ "sainnhe/gruvbox-material", lazy = false, priority = 1000 },
	{ "folke/tokyonight.nvim", lazy = false, priority = 1000 },
	{ "adigitoleo/vim-mellow", lazy = false, priority = 1000 },
	{ "rose-pine/neovim", lazy = false, priority = 1000 },
	{ "catppuccin/nvim", lazy = false, priority = 1000 },
	{ "ivanhernandez/pompeii", lazy = false, priority = 1000 },
	{ "tobi-wan-kenobi/zengarden", lazy = false, priority = 1000 },
	{ "maxmx03/solarized.nvim", lazy = false, priority = 1000 },
	{ "sainnhe/everforest", lazy = false, priority = 1000 },
	{ "olimorris/onedarkpro.nvim", lazy = false, priority = 1000 },
	{ "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
	{ "rafi/awesome-vim-colorschemes", lazy = false, priority = 1000 },
	{ "savq/melange-nvim", lazy = false, priority = 1000 },
	{ "nlknguyen/papercolor-theme", lazy = false, priority = 1000 },
	{ "sainnhe/edge", lazy = false, priority = 1000 },
	{ "mofiqul/vscode.nvim", lazy = false, priority = 1000 },
	{ "uZer/pywal16.nvim", lazy = false, priority = 1000 },
	{ "RRethy/base16-nvim", lazy = false, priority = 1000 },
	{
		"github-main-user/lytmode.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("lytmode").setup()
		end,
	},

	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
			vim.g.mkdp_browser = "/sbin/zen-browser"
		end,
		ft = { "markdown" },
	},

	{
		"lambdalisue/vim-suda",
		cmd = { "SudaWrite", "SudaRead" },
	},
	{
		"stevearc/oil.nvim",
		---@module 'oil'
		---@type oil.SetupOpts

		cmd = { "Oil" },
		opts = {},
		-- Optional dependencies
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
		lazy = false,
	},
	-- {
	--   "epwalsh/obsidian.nvim",
	--   version = "*",
	--   lazy = true,
	--   ft = "markdown",
	--   -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
	--   -- event = {
	--   --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
	--   --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
	--   --   -- refer to `:h file-pattern` for more examples
	--   --   "BufReadPre path/to/my-vault/*.md",
	--   --   "BufNewFile path/to/my-vault/*.md",
	--   -- },
	--   dependencies = {
	--     -- Required.
	--     "nvim-lua/plenary.nvim",
	--
	--     -- see below for full list of optional dependencies 👇
	--   },
	--   opts = {
	--
	--     disable_frontmatter = true,
	--     workspaces = {
	--       {
	--         name = "personal",
	--         path = "~/vaults/personal",
	--       }
	--     },
	--
	--     -- see below for full list of options 👇
	--   }
	-- },
	{
		{
			"chomosuke/typst-preview.nvim",
			ft = "typst",
			version = "1.*",
			opts = {}, -- lazy.nvim will implicitly calls `setup {}`
		},
		{
			"https://git.sr.ht/~nedia/auto-save.nvim",
			event = { "BufReadPre" },
			opts = {
				events = { "InsertLeave", "BufLeave" },
				silent = false,
				exclude_ft = { "neo-tree" },
			},
		},

		{
			"stevearc/conform.nvim",
			event = { "BufReadPre", "BufNewFile" },

			opts = {
				formatters = {},

				formatters_by_ft = {
					bash = { "shfmt" },
					fish = { "fish_indent" },
					go = { "golines" },
					lua = { "stylua" },
					python = { "isort", "black" },
					sh = { "shfmt" },
					rust = { "rustfmt", lsp_format = "fallback" },
					yaml = { "prettier_yaml" },

					-- C / C++
					c = { "clang-format", lsp_format = "fallback" },
					cpp = { "clang-format", lsp_format = "fallback" },
				},

				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},
			},

			config = function(_, opts)
				require("conform").setup(opts)

				-- Toggle command
				vim.api.nvim_create_user_command("FormatToggle", function(args)
					local scope = vim.g
					if args.bang then
						scope = vim.b
					end

					scope.disable_autoformat = not scope.disable_autoformat

					local msg = scope.disable_autoformat and "Disabled format on save" or "Enabled format on save"

					vim.notify(msg, vim.log.levels.INFO)
				end, {
					desc = "Toggle format on save",
					bang = true,
				})

				-- Keymaps using vim.api.nvim_set_keymap
				vim.api.nvim_set_keymap("n", "<leader>co", ":ConformInfo<CR>", { noremap = true, silent = true })

				vim.api.nvim_set_keymap("n", "<leader>ct", ":FormatToggle<CR>", { noremap = true, silent = true })
			end,
		},
	},
}
