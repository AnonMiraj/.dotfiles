local M =
{
  "AnonMiraj/competitest.nvim",
  --a Neovim plugin to automate testcases management and checking for Competitive Programming
  ft = "cpp",
  -- cmd = "Competitest",
  -- key = "<leader>cr",
  dependencies = {
    -- format & linting
    {
      "MunifTanjim/nui.nvim",
    },
  },
  config = function()
    require("competitest").setup()
  end,


}

function M.init()
  vim.keymap.set('n', '<leader>crc', '<cmd>CompetiTest receive contest <CR>', { desc = 'receive contest' })
  vim.keymap.set('n', '<leader>crp', '<cmd>CompetiTest receive problem <CR>', { desc = 'receive problem' })
  vim.keymap.set('n', '<leader>cra', '<cmd>CompetiTest add_testcase <CR>', { desc = 'add testcase' })
  vim.keymap.set('n', '<leader>cre', '<cmd>CompetiTest edit_testcase <CR>', { desc = 'edit testcase' })
  vim.keymap.set('n', '<leader>crr', '<cmd>CompetiTest run <CR>', { desc = 'run code' })
  -- judge="$(JUDGE)",
end

function M.config()
  require('competitest').setup {
    -- received_problems_path = "$(HOME)/library/Competitive Programming/$(JUDGE)/$(CONTEST)/$(PROBLEM).$(FEXT)",
    function(task, file_extension)
      local hyphen = string.find(task.group, " - ")
      local judge, contest
      if not hyphen then
        judge = task.group
        contest = "unknown_contest"
      else
        judge = string.sub(task.group, 1, hyphen - 1)
        contest = string.sub(task.group, hyphen + 3)
      end
    end,
    received_problems_path = "$(HOME)/library/Competitive Programming/$(JUDGE)/$(CONTEST)/$(PROBLEM).$(FEXT)",

    received_contests_directory = "$(HOME)/library/Competitive Programming/$(JUDGE)/$(CONTEST)",
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
    },
  }
end

return M
