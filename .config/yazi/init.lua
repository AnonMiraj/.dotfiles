require("zoxide"):setup({
	update_db = true,
})
-- require("searchjump"):setup({
-- 	unmatch_fg = catppuccin_palette.overlay0,
-- 	match_str_fg = catppuccin_palette.peach,
-- 	match_str_bg = catppuccin_palette.base,
-- 	first_match_str_fg = catppuccin_palette.lavender,
-- 	first_match_str_bg = catppuccin_palette.base,
-- 	lable_fg = catppuccin_palette.green,
-- 	lable_bg = catppuccin_palette.base,
-- 	only_current = true,
-- 	show_search_in_statusbar = true,
-- 	auto_exit_when_unmatch = true,
-- 	enable_capital_lable = false,
-- 	search_patterns = {}, -- demo:{"%.e%d+","s%d+e%d+"}
-- })
--
-- require("yatline"):setup({
-- 	section_separator = { open = "", close = "" },
-- 	inverse_separator = { open = "", close = "" },
-- 	part_separator = { open = "", close = "" },
--
-- 	tab_width = 20,
-- 	tab_use_inverse = true,
--
-- 	show_background = false,
--
-- 	display_header_line = true,
-- 	display_status_line = true,
--
-- 	header_line = {
-- 		left = {
-- 			section_a = {
-- 				{ type = "line", custom = false, name = "tabs", params = { "left" } },
-- 			},
-- 			section_b = {
-- 				{ type = "coloreds", custom = false, name = "githead" },
-- 			},
-- 			section_c = {},
-- 		},
-- 		right = {
-- 			section_a = {
-- 				{ type = "string", custom = false, name = "tab_path" },
-- 			},
-- 			section_b = {
-- 				{ type = "coloreds", custom = false, name = "task_workload" },
-- 			},
-- 			section_c = {
-- 				{ type = "coloreds", custom = false, name = "task_states" },
-- 			},
-- 		},
-- 	},
--
-- 	status_line = {
-- 		left = {
-- 			section_a = {
-- 				{ type = "string", custom = false, name = "tab_mode" },
-- 			},
-- 			section_b = {
-- 				{ type = "string", custom = false, name = "hovered_size" },
-- 			},
-- 			section_c = {
-- 				{ type = "string", custom = false, name = "hovered_name" },
-- 			},
-- 		},
-- 		right = {
-- 			section_a = {
-- 				{ type = "string", custom = false, name = "cursor_position" },
-- 			},
-- 			section_b = {
-- 				{ type = "string", custom = false, name = "cursor_percentage" },
-- 			},
-- 			section_c = {
-- 				{ type = "coloreds", custom = false, name = "count",      params = "true" },
-- 				-- { type = "string", custom = false, name = "hovered_file_extension", params = { true } },
-- 				{ type = "coloreds", custom = false, name = "permissions" },
-- 			},
-- 		},
-- 	},
-- })
--
-- require("yatline-githead"):setup({
-- 	show_branch = true,
-- 	branch_prefix = "",
-- 	branch_symbol = "",
-- 	branch_borders = "",
--
-- 	commit_symbol = " ",
--
-- 	show_stashes = true,
-- 	stashes_symbol = " ",
--
-- 	show_state = true,
-- 	show_state_prefix = true,
-- 	state_symbol = "󱅉",
--
-- 	show_staged = true,
-- 	staged_symbol = " ",
--
-- 	show_unstaged = true,
-- 	unstaged_symbol = " ",
--
-- 	show_untracked = true,
-- 	untracked_symbol = " ",
--
-- })
--
require("git"):setup {
	order = 1500,
}

require("pref-by-location"):setup({
	-- Disable this plugin completely.
	-- disabled = false -- true|false (Optional)

	-- Hide "enable" and "disable" notifications.
	-- no_notify = false -- true|false (Optional)

	-- You can backup/restore this file. But don't use same file in the different OS.
	-- save_path =  -- full path to save file (Optional)
	--       - Linux/MacOS: os.getenv("HOME") .. "/.config/yazi/pref-by-location"
	--       - Windows: os.getenv("APPDATA") .. "\\yazi\\config\\pref-by-location"

	-- You don't have to set "prefs". Just use keymaps below work just fine
	prefs = { -- (Optional)
		-- location: String | Lua pattern (Required)
		--   - Support literals full path, lua pattern (string.match pattern): https://www.lua.org/pil/20.2.html
		--     And don't put ($) sign at the end of the location. %$ is ok.
		--   - If you want to use special characters (such as . * ? + [ ] ( ) ^ $ %) in "location"
		--     you need to escape them with a percent sign (%).
		--     Example: "/home/test/Hello (Lua) [world]" => { location = "/home/test/Hello %(Lua%) %[world%]", ....}

		-- sort: {} (Optional) https://yazi-rs.github.io/docs/configuration/yazi#manager.sort_by
		--   - extension: "none"|"mtime"|"btime"|"extension"|"alphabetical"|"natural"|"size"|"random", (Optional)
		--   - reverse: true|false (Optional)
		--   - dir_first: true|false (Optional)
		--   - translit: true|false (Optional)
		--   - sensitive: true|false (Optional)

		-- linemode: "none" |"size" |"btime" |"mtime" |"permissions" |"owner" (Optional) https://yazi-rs.github.io/docs/configuration/yazi#manager.linemode
		--   - Custom linemode also work. See the example below

		-- show_hidden: true|false (Optional) https://yazi-rs.github.io/docs/configuration/yazi#manager.show_hidden

		-- Some examples:
		-- Match any folder which has path start with "/mnt/remote/". Example: /mnt/remote/child/child2
		-- Match any folder with name "Downloads"
		{ location = ".*/Downloads",      sort = { "btime", reverse = true, dir_first = true }, linemode = "btime" },
		-- Match exact folder with absolute path "/home/test/Videos"
		{ location = "/home/nir/YouTube", sort = { "btime", reverse = true, dir_first = true }, linemode = "btime" },
		{ location = "/media.*",          sort = { "btime", reverse = true, dir_first = true }, linemode = "btime" },
		-- DO NOT ADD location = ".*". Which currently use your yazi.toml config as fallback.
		-- That mean if none of the saved perferences is matched, then it will use your config from yazi.toml.
		-- So change linemode, show_hidden, sort_xyz in yazi.toml instead.
	},
})
require("session"):setup {
	sync_yanked = true,
}
require("fs-usage"):setup()
require("sshfs"):setup()
require('spot'):setup {
	metadata_section = {
		enable = true,
		hash_cmd = 'xxhsum',          -- other hashing commands may be slower
		hash_filesize_limit = 150,    -- in MB, set 0 to disable
		relative_time = true,         -- 2026-01-01 or n days ago
		time_format = '%Y-%m-%d %H:%M', -- https://www.man7.org/linux/man-pages/man3/strftime.3.html
		show_compression = 'size', ---@type false|"size"|"percentage"
	},
	plugins_section = {
		enable = true,
	},
	style = {
		section = 'green',
		key = 'reset',
		value = 'blue',
		colorize_metadata = true,
		height = 20,
		width = 60,
		key_length = 15,
	},
}
require("hover-after-moved"):setup()
require("recycle-bin"):setup()
