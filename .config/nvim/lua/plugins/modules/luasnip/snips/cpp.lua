local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local parse = ls.parser.parse_snippet
local fmt = require("luasnip.extras.fmt").fmt


ls.add_snippets("cpp", {}, {})
local TTEMP = [[
]]

-- Create a snippet that starts with the cursor before main() function
-- local TTEMPCCC = TTEMP:gsub("void solve%(%) {}", "${0}void solve%() {")
-- Create a snippet with cin >> n; line
-- gsub("void solve%(%) {}", "")

local TTCCC = TTEMP:gsub("${1~}", "\n  cin >> n;")
local TTEMPCCC = TTCCC:gsub("void solve%(%) { ${0} }", "${0}void solve%(%)\n{ ${1} }")
-- Create a snippet without cin >> n; line
local TCCC = TTEMP:gsub("${1~}", "")
local TEMPCCC = TCCC:gsub("void solve%(%) { ${0} }", "${0}void solve%(%)\n{ ${1} }")

ls.add_snippets("cpp", {
    parse({ trig = "TTEMP" }, TTEMPCCC),
    parse({ trig = "TEMP" }, TEMPCCC),
}, {})


