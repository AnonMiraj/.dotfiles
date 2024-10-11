local M =
{
  "kevinhwang91/nvim-ufo",
  --The goal of nvim-ufo is to make Neovim's fold look modern and keep high performance.
  dependencies = {
    "kevinhwang91/promise-async",
    {
      "luukvbaal/statuscol.nvim",
    },
  },
  event = "BufReadPost",
}
function M.config()
  local builtin = require "statuscol.builtin"
  require("statuscol").setup {
    relculright = true,
    segments = {
      { text = { builtin.foldfunc },      click = "v:lua.ScFa" },
      { text = { "%s" },                  click = "v:lua.ScSa" },
      { text = { builtin.lnumfunc, " " }, click = "v.lua.ScLa" },
    },
  }

  -- Main configuration ---------------------------------------------------------


  require("ufo").setup {
    Keys = { "zf", "zo", "za", "zc", "zM", "zR" },
    provider_selector = function()
      return { "treesitter", "indent" }
    end
  }
end

return M
