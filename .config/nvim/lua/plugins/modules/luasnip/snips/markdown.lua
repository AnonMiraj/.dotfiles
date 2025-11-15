local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local ts_utils = require("nvim-treesitter.ts_utils")

-- Detect if we are inside a Markdown math block ($...$ or $$...$$)
local function in_math_ts()
  local node = ts_utils.get_node_at_cursor()
  while node do
    if node:type() == "inline_formula" or node:type() == "displayed_equation" then
      return true
    end
    node = node:parent()
  end
  return false
end

-- Example: define math-only snippets for Markdown
ls.add_snippets("markdown", {
  s(
    { trig = "ff", wordTrig = true, condition = in_math_ts },
    { t("\\frac{"), i(1), t("}{"), i(2), t("}") }
  ),
  s(
    { trig = "sq", wordTrig = true, condition = in_math_ts },
    { t("\\sqrt{"), i(1), t("}") }
  ),
})
ls.filetype_extend("markdown", { "tex" })

