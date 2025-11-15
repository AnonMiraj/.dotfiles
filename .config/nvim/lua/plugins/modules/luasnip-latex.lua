
return {
  "iurimateus/luasnip-latex-snippets.nvim",
  dependencies = {
    "L3MON4D3/LuaSnip",
    "lervag/vimtex", -- optional if using treesitter
  },

  -- Only load when editing these filetypes
  ft = { "tex", "markdown" },

  config = function()
    require("luasnip-latex-snippets").setup({
      -- use_treesitter = true, -- enable if you prefer treesitter
      allow_on_markdown = true, -- adds snippets also to markdown
    })
  end,
}

