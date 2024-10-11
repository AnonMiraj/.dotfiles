local M =
{
  "xeluxee/competitest.nvim",
  --a Neovim plugin to automate testcases management and checking for Competitive Programming
  ft = "cpp",
  -- cmd = "Competitest",
  -- key = "<leader>cr",
  keys = {
    { ' rc', '<cmd>CompetiTest receive contest <CR>', { desc = 'receive contest' } },
    { ' rp', '<cmd>CompetiTest receive problem <CR>', { desc = 'receive problem' } },
    { 'cra', '<cmd>CompetiTest add_testcase <CR>',    { desc = 'add testcase' } },
    { ' re', '<cmd>CompetiTest edit_testcase <CR>',   { desc = 'edit testcase' } },
    { ' rr', '<cmd>CompetiTest run <CR>',             { desc = 'run code' } }
  },
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
  -- judge="$(JUDGE)",
end

function M.config()
  require('competitest').setup {
    compile_command = {
      c    = { exec = 'gcc', args = { '-DALGOAT', '-Wall', '$(FNAME)', '-o', '$(FNOEXT)' } },
      cpp  = { exec = 'g++', args = { '-std=c++17', '-DALGOAT', '-Wall', '$(FNAME)', '-o', '$(FNOEXT)','-g' } },
      py   = { exec = 'python', args = { '$(FNAME)' } },
      rust = { exec = 'rustc', args = { '$(FNAME)' } },
      java = { exec = 'javac', args = { '$(FNAME)' } },
    },
    received_problems_path = "$(HOME)/Competitive Programming/$(JUDGE)/$(CONTEST)/$(PROBLEM).$(FEXT)",
    received_contests_directory = "$(HOME)/Competitive Programming/$(JUDGE)/$(CONTEST)",
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
