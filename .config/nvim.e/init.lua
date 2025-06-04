vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.syntax = "on"
-- vim.opt.filetype = "plugin"
vim.opt.compatible = false
vim.opt.autoread = true
vim.opt.foldmethod = "marker"
vim.opt.autoindent = true
vim.opt.clipboard:append("unnamedplus")
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.autochdir = true
-- vim.cmd("colorscheme desert")
vim.opt.cursorline = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

-- vim.api.nvim_set_keymap("n", " r", ":w!<CR>:!compile '%:p:r'<CR>", { noremap = true, silent = true })
vim.keymap.set("n", " s", "<cmd> w !parse_cp ~/ezz_cp_sheet.xlsx <CR>")
vim.keymap.set("n", " c", "<cmd> %y+ <CR>")
vim.api.nvim_set_keymap("x", "<", "<gv", { noremap = true })
vim.api.nvim_set_keymap("x", ">", ">gv", { noremap = true })
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.vim/undo")
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000
vim.opt.swapfile = false

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
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
					cpp = {
						exec = "g++",
						args = { "-DALGOAT", "-Wall", "$(FNAME)", "-o", "$(FNOEXT).o", "-g" },
					},
					haskell = {
						exec = "ghc",
						args = { "-dynamic", "$(FNAME)", "-o", "$(FNOEXT).ex" },
					},
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

			-- Define key mappings for competitest within the config function
			vim.api.nvim_set_keymap(
				"n",
				"<leader>rc",
				"<cmd>CompetiTest receive contest<CR>",
				{ desc = "receive contest", noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>rp",
				"<cmd>CompetiTest receive problem<CR>",
				{ desc = "receive problem", noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>ra",
				"<cmd>CompetiTest add_testcase<CR>",
				{ desc = "add testcase", noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>re",
				"<cmd>CompetiTest edit_testcase<CR>",
				{ desc = "edit testcase", noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"n",
				"<leader>rr",
				"<cmd>CompetiTest run<CR>",
				{ desc = "run code", noremap = true, silent = true }
			)

			vim.api.nvim_set_keymap(
				"n",
				"<leader>rsp",
				"<cmd>lua (function() "
				.. "require('competitest').setup { received_files_extension = 'hs' } "
				.. "vim.cmd('CompetiTest receive problem') "
				.. "require('competitest').setup { received_files_extension = 'cpp' } "
				.. "end)()<CR>",
				{ desc = "receive problem with rs and revert to cpp", noremap = true, silent = true }
			)

			vim.api.nvim_set_keymap(
				"n",
				"<leader>rsc",
				"<cmd>lua (function() "
				.. "require('competitest').setup { received_files_extension = 'hs' } "
				.. "vim.cmd('CompetiTest receive contest') "
				.. "end)()<CR>",
				{ desc = "receive problem with rs and revert to cpp", noremap = true, silent = true }
			)
		end,
	},

	{
		"nvim-lua/plenary.nvim",
		lazy = false,
	},

	{
		"nvim-telescope/telescope.nvim",
		requires = { { "nvim-lua/plenary.nvim" } },
		lazy = false,
	},
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
	},
	{
		"nvimdev/guard.nvim",
		-- lazy load by ft
		ft = { "lua", "c", "markdown", "rust", "cpp" },
		-- Builtin configuration, optional
		dependencies = {
			"nvimdev/guard-collection",
		},
		lazy = false,
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",

		dependencies = {
			-- Snippet Engine & its associated nvim-cmp source
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",

			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"onsails/lspkind-nvim",
			"hrsh7th/cmp-cmdline",
		},
	},
{ "ellisonleao/gruvbox.nvim", priority = 1000 , config = true, opts = ...}
})

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if vim.fn.argc() == 0 then
			require("telescope.builtin").oldfiles()
		end
	end,
})

require("luasnip.loaders.from_snipmate").lazy_load()
local ls = require("luasnip")
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
		{ name = "buffer",  keyword_length = 3 },
	},
})

vim.api.nvim_set_keymap(
	"n",
	"<leader>fm",
	"<cmd>Guard fmt<CR>",
	{ desc = "format code", noremap = true, silent = true }
)
local ft = require("guard.filetype")

-- Assuming you have guard-collection
-- Put this in your ftplugin/lang.lua to lazy load guard
ft("cpp"):fmt("clang-format")
ft("lua"):fmt("lsp"):append("stylua"):lint("selene")
ft("python"):fmt("autopep8")

-- change this anywhere in your config, these are the defaults
vim.g.guard_config = {
	-- format on write to buffer
	fmt_on_save = false,
	-- use lsp if no formatter was defined for this filetype
	-- lsp_as_default_formatter = false,
	-- whether or not to save the buffer after formatting
	save_on_fmt = true,
}

vim.o.background = "light"
vim.cmd([[colorscheme gruvbox]])
