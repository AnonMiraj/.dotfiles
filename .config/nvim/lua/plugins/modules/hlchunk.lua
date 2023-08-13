local M={
    "shellRaining/hlchunk.nvim",
    --similar to indent-blankline, this plugin can highlight the indent line,
    --and highlight the code chunk according to the current cursor position.
    event = "BufReadPost",
  }
function M.config()
local present, hlchunk = pcall(require, "hlchunk")

if not present then
  return
end

hlchunk.setup {
  chunk = {
    enable = false,
    support_filetypes = {
      -- "*.json",
      "*.lua",
      "*.cpp",
      "*.py",
    },
    chars = {
      horizontal_line = "─",
      vertical_line = "│",
      left_top = "╭",
      left_bottom = "╰",
      right_arrow = ">",
    },
    style = "#806d9c",
  },

  indent = {
    enable = true,
    use_treesitter = false,
    -- You can uncomment to get more indented line look like
    chars = {
      "│",
      "¦",
      "┆",
      "┊",
    },
    -- you can uncomment to get more indented line style
    style = {
      "#d2c510",
      "#F2B807",
      "#F28705",
      "#C52104",
      "#710301",
      "#e70602",
    },
    exclude_filetype = {
      terminal = true,
      dashboard = true,
      help = true,
      lspinfo = true,
      packer = true,
      checkhealth = true,
      man = true,
      mason = true,
      plugin = true,
    },
  },

  line_num = {
    enable = false,
    support_filetypes = {
      "...",
    },
    style = "#806d9c",
  },

  blank = {
    enable = false,
    chars = {
      "",
    },
    style = {
      vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID "Whitespace"), "fg", "gui"),
    },
    exclude_filetype = "...",
  },
}
end
  return M
