local M =
{
  "karb94/neoscroll.nvim",
  --Smooth scrolling for window movement commands
  keys = { "<C-d>", "<C-u>" },
  config = function()
    require("neoscroll").setup {
      mappings = {
        "<C-u>",
        "<C-d>",
      },
    }
  end,
}
return M
