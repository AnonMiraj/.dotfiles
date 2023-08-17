local M = { "akinsho/nvim-bufferline.lua", lazy = false }
function M.init()
  vim.keymap.set('n', '<leader>b', '<CMD>tabnew<CR>', { desc = "New buffer" })
  vim.keymap.set('n', '<tab>', '<CMD>BufferLineCycleNext<CR>', {})
  vim.keymap.set('n', '<S-tab>', '<CMD>BufferLineCyclePrev<CR>', {})
  vim.keymap.set('n', '<leader>x', '<CMD>BufferLinePickClose<CR>', { desc = "Close buffer" })
  vim.keymap.set('n', '<leader>p', '<CMD>BufferLinePick<CR>', { desc = "pick buffer" })
end

function M.config()
  require("bufferline").setup {
    options = {
      hover = {
        enabled = true,
        delay = 200,
        reveal = { 'close' },
      },
      view = "multiwindow",
      numbers = function(opts)
        return string.format("%s", opts.ordinal)
      end,
      modified_icon = "●",
      max_prefix_length = 5,
      tab_size = 18,
      diagnostics = "nvim_lsp",
      separator_style = { "|", "" },
    },
  }
  -- vim.cmd.colorscheme "" -- there should be a better fix for this
end

return M
