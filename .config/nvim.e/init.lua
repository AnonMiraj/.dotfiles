vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.syntax = "on"
vim.opt.compatible = false
vim.opt.autoread = true
vim.opt.foldmethod = "marker"
vim.opt.termguicolors = true

vim.o.background = "light"
-- Line Numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.autoindent = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

-- Clipboard
vim.opt.clipboard:append("unnamedplus")

-- File Management
vim.opt.autochdir = true
vim.opt.swapfile = false

-- Undo Configuration
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.vim/undo")
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Custom shortcuts
--
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", " s", "<cmd> w !parse_cp ~/ezz_cp_sheet.xlsx <CR>")
vim.keymap.set("n", " c", "<cmd> %y+ <CR>")

-- Visual mode indentation (keep selection)
vim.api.nvim_set_keymap("x", "<", "<gv", { noremap = true })
vim.api.nvim_set_keymap("x", ">", ">gv", { noremap = true })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

	{
		"xeluxee/competitest.nvim",
		dependencies = "MunifTanjim/nui.nvim",
		config = function()
			require("competitest").setup({
				compile_command = {
					c = { exec = "gcc", args = { "-DALGOAT", "-Wall", "$(FNAME)", "-o", "$(FNOEXT).o" } },
					cpp = { exec = "g++", args = { "-DALGOAT", "-Wall", "$(FNAME)", "-o", "$(FNOEXT).o", "-g" } },
					haskell = { exec = "ghc", args = { "-dynamic", "$(FNAME)", "-o", "$(FNOEXT).ex" } },
					py = { exec = "python", args = { "$(FNAME)" } },
					rust = { exec = "rustc", args = { "$(FNAME)", "--crate-name", "test" } },
					java = { exec = "javac", args = { "$(FNAME)" } },
				},
				run_command = {
					c = { exec = "./$(FNOEXT).o" },
					cpp = { exec = "./$(FNOEXT).o" },
					haskell = { exec = "./$(FNOEXT).ex" },
					rust = { exec = "./test" },
					python = { exec = "python", args = { "$(FNAME)" } },
					java = { exec = "java", args = { "$(FNOEXT)" } },
				},
				received_problems_path = "$(HOME)/Competitive Programming/$(JUDGE)/$(CONTEST)/$(PROBLEM).$(FEXT)",
				received_contests_directory = "$(HOME)/Competitive Programming/$(JUDGE)/$(CONTEST)",
				received_contests_problems_path = "$(PROBLEM).$(FEXT)",
				received_problems_prompt_path = false,
				testcases_use_single_file = true,
				evaluate_template_modifiers = true,
				received_contests_prompt_directory = false,
				received_contests_prompt_extension = false,
				open_received_contests = false,
				received_files_extension = "cpp",
				template_file = {
					cpp = "~/.config/nvim/template/CPP.cpp",
					rs = "~/.config/nvim/template/RUST.rs",
					hs = "~/.config/nvim/template/HASKELL.hs",
				},
			})

			-- Competitive Programming Key Mappings
			local keymap_opts = { noremap = true, silent = true }

			vim.api.nvim_set_keymap(
				"n",
				"<leader>rc",
				"<cmd>CompetiTest receive contest<CR>",
				vim.tbl_extend("force", keymap_opts, { desc = "receive contest" })
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>rp",
				"<cmd>CompetiTest receive problem<CR>",
				vim.tbl_extend("force", keymap_opts, { desc = "receive problem" })
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>ra",
				"<cmd>CompetiTest add_testcase<CR>",
				vim.tbl_extend("force", keymap_opts, { desc = "add testcase" })
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>re",
				"<cmd>CompetiTest edit_testcase<CR>",
				vim.tbl_extend("force", keymap_opts, { desc = "edit testcase" })
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>rr",
				"<cmd>CompetiTest run<CR>",
				vim.tbl_extend("force", keymap_opts, { desc = "run code" })
			)

			-- Special Haskell configurations
			vim.api.nvim_set_keymap(
				"n",
				"<leader>rsp",
				"<cmd>lua (function() "
					.. "require('competitest').setup { received_files_extension = 'hs' } "
					.. "vim.cmd('CompetiTest receive problem') "
					.. "require('competitest').setup { received_files_extension = 'cpp' } "
					.. "end)()<CR>",
				vim.tbl_extend("force", keymap_opts, { desc = "receive problem with Haskell" })
			)

			vim.api.nvim_set_keymap(
				"n",
				"<leader>rsc",
				"<cmd>lua (function() "
					.. "require('competitest').setup { received_files_extension = 'hs' } "
					.. "vim.cmd('CompetiTest receive contest') "
					.. "end)()<CR>",
				vim.tbl_extend("force", keymap_opts, { desc = "receive contest with Haskell" })
			)
		end,
	},

	{
		"nvim-lua/plenary.nvim",
		lazy = false,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		lazy = false,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"c",
					"cpp",
					"lua",
					"vim",
					"vimdoc",
					"query",
					"python",
					"rust",
					"javascript",
					"typescript",
					"html",
					"css",
					"json",
					"yaml",
					"markdown",
					"bash",
				},
				sync_install = false,
				auto_install = true,
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true,
				},
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<C-space>",
						node_incremental = "<C-space>",
						scope_incremental = "<C-s>",
						node_decremental = "<C-backspace>",
					},
				},
			})
		end,
	},

	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
	},

	{
		"nvimdev/guard.nvim",
		ft = { "lua", "c", "markdown", "rust", "cpp" },
		dependencies = { "nvimdev/guard-collection" },
		lazy = false,
	},

	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"onsails/lspkind-nvim",
			"hrsh7th/cmp-cmdline",
		},
	},
	--
	-- {
	-- 	"vimpostor/vim-lumen",
	-- },
	{
		"sainnhe/gruvbox-material",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.gruvbox_material_enable_italic = true
			vim.g.gruvbox_material_background = "soft"
			vim.g.everforest_diagnostic_text_highlight = 1
			vim.o.background = "light"
			vim.cmd.colorscheme("gruvbox-material")
		end,
	},
	{
		"sainnhe/everforest",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.everforest_enable_italic = true
			vim.g.everforest_background = "medium"
			vim.o.background = "light"
			vim.g.everforest_diagnostic_text_highlight = 1
			-- vim.cmd.colorscheme("everforest")
		end,
	},
})

-- Open telescope oldfiles on startup if no files are opened
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then
			require("telescope.builtin").oldfiles()
		end
	end,
})

require("luasnip.loaders.from_snipmate").lazy_load()
local ls = require("luasnip")

-- Snippet key mappings
vim.keymap.set({ "i" }, "<C-K>", function()
	ls.expand()
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-L>", function()
	ls.jump(1)
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-J>", function()
	ls.jump(-1)
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-E>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, { silent = true })

local cmp = require("cmp")
local luasnip = require("luasnip")

luasnip.config.setup({})

cmp.setup({
	completion = {
		autocomplete = false,
		completeopt = "menu,menuone,noinsert",
	},
	mapping = cmp.mapping.preset.insert({
		["<C-n>"] = cmp.mapping.select_next_item(),
		["<C-p>"] = cmp.mapping.select_prev_item(),
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete({}),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = {
		{ name = "luasnip" },
		{ name = "path" },
		{ name = "nvim_lua" },
		{ name = "buffer", keyword_length = 3 },
	},
})

vim.api.nvim_set_keymap(
	"n",
	"<leader>fm",
	"<cmd>Guard fmt<CR>",
	{ desc = "format code", noremap = true, silent = true }
)

vim.keymap.set("n", "<leader>fw", require("telescope.builtin").live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>th", require("telescope.builtin").colorscheme, { desc = "Preview Colorscheme" })
local ft = require("guard.filetype")

-- Language-specific formatters
ft("cpp"):fmt("clang-format")
ft("lua"):fmt("lsp"):append("stylua"):lint("selene")
ft("python"):fmt("autopep8")

-- Guard configuration
vim.g.guard_config = {
	fmt_on_save = false,
	save_on_fmt = true,
}
