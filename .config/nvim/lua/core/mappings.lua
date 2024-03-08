local M = {}

function M.setup()
  M.general()
  M.movements()
end

function M.general()
  -- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x \" % \"<CR>", { silent = true, desc = 'chmod +x file' })
  --    vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
  vim.keymap.set("n", "<leader>fm", function() vim.lsp.buf.format { async = true } end, { desc = 'LSP formatting' })
  -- vim.keymap.set("n", "<leader>tt", "<cmd> TroubleToggle <CR>", { desc = 'Toggle Trouble' })
end

function M.movements()
  vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
  vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

  -- Disable arrow keys
  vim.keymap.set({ "n", "v", "x", "i" }, "<Up>", "<Nop>")
  vim.keymap.set({ "n", "v", "x", "i" }, "<Down>", "<Nop>")
  vim.keymap.set({ "n", "v", "x", "i" }, "<Left>", "<Nop>")
  vim.keymap.set({ "n", "v", "x", "i" }, "<Right>", "<Nop>")
  -- navigate within insert mode
  vim.keymap.set("i", "<C-h>", "<Left>")
  vim.keymap.set("i", "<C-l>", "<Right>")
  vim.keymap.set("i", "<C-j>", "<Down>")
  vim.keymap.set("i", "<C-k>", "<Up>")

  -- save
  -- vim.keymap.set("n", "<C-s>", "<cmd> w <CR>")

  -- Copy all
  vim.keymap.set("n", "<C-c>", "<cmd> %y+ <CR>")

  -- new buffer
  vim.keymap.set("n", "<leader>b", "<cmd> enew <CR>", { desc = 'New buffer' })

  -- toggle comment in both modes
  -- vim.keymap.set("n", "<leader>/", M.commentline, { desc = 'Toggle comment' })
  -- vim.keymap.set("v", "<leader>/", "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
    -- { desc = 'Toggle comment' })
end

-- function M.commentline()
--   require("Comment.api").toggle.linewise.current()
-- end

M.setup()
