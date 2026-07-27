{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.nvf.settings.vim = {
    keymaps = [
      # Leader
      {
        mode = "n";
        key = ";";
        action = ":";
      }
      {
        mode = "n";
        key = "<leader>w";
        action = "<cmd>w<cr>";
      }
      {
        mode = "n";
        key = "<leader>q";
        action = "<cmd>q<cr>";
      }
      {
        mode = "n";
        key = "<leader>fm";
        action = "<cmd>lua vim.lsp.buf.format { async = true }<cr>";
      }
      {
        mode = "n";
        key = " cc";
        action = "<cmd> %y+ <cr>";
      }
      {
        mode = "x";
        key = "<";
        action = "<gv";
      }
      {
        mode = "x";
        key = ">";
        action = ">gv";
      }
      {
        mode = "n";
        key = "<BS>";
        action = "<CMD>Oil<CR>";
      }

      # Movement — wrap-aware j/k
      {
        mode = "n";
        key = "j";
        action = "v:count == 0 ? 'gj' : 'j'";
        expr = true;
      }
      {
        mode = "n";
        key = "k";
        action = "v:count == 0 ? 'gk' : 'k'";
        expr = true;
      }

      # Insert mode navigation
      {
        mode = "i";
        key = "<C-h>";
        action = "<Left>";
      }
      {
        mode = "i";
        key = "<C-l>";
        action = "<Right>";
      }
      {
        mode = "i";
        key = "<C-j>";
        action = "<Down>";
      }
      {
        mode = "i";
        key = "<C-k>";
        action = "<Up>";
      }

      # Copy all
      {
        mode = "n";
        key = "<C-c>";
        action = "<cmd> %y+ <cr>";
      }

      # Buffer
      {
        mode = "n";
        key = "<leader>b";
        action = "<cmd> enew <cr>";
      }

      # Barbar buffer navigation
      {
        mode = "n";
        key = "<S-tab>";
        action = "<Cmd>BufferPrevious<CR>";
      }
      {
        mode = "n";
        key = "<tab>";
        action = "<Cmd>BufferNext<CR>";
      }
      {
        mode = "n";
        key = "<leader>x";
        action = "<Cmd>BufferClose<CR>";
      }
      {
        mode = "n";
        key = "<leader>p";
        action = "<Cmd>BufferPick<CR>";
      }
      {
        mode = "n";
        key = "<A-p>";
        action = "<Cmd>BufferMovePrevious<CR>";
      }
      {
        mode = "n";
        key = "<A-n>";
        action = "<Cmd>BufferMoveNext<CR>";
      }

      # Trouble
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
      }
      {
        mode = "n";
        key = "<leader>cs";
        action = "<cmd>Trouble symbols toggle<cr>";
      }
      {
        mode = "n";
        key = "<leader>cl";
        action = "<cmd>Trouble lsp toggle<cr>";
      }
      {
        mode = "n";
        key = "<leader>xL";
        action = "<cmd>Trouble loclist toggle<cr>";
      }
      {
        mode = "n";
        key = "<leader>xQ";
        action = "<cmd>Trouble qflist toggle<cr>";
      }

      # FFF fuzzy finder
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>lua require('fff').find_files()<cr>";
      }
      {
        mode = "n";
        key = "<leader>fa";
        action = "<cmd>lua require('fff').find_files()<cr>";
      }
      {
        mode = "n";
        key = "<leader>fo";
        action = "<cmd>lua require('fff').find_files()<cr>";
      }
      {
        mode = "n";
        key = "<leader>fw";
        action = "<cmd>lua local dir = vim.fn.expand('%:p:h'); if dir == '' then dir = vim.fn.getcwd() end; require('fff').live_grep({ base_path = dir })<cr>";
      }
      {
        mode = "n";
        key = "<leader>fW";
        action = "<cmd>lua require('fff').live_grep()<cr>";
      }
      {
        mode = "n";
        key = "<leader>fc";
        action = "<cmd>lua require('fff').live_grep({ query = vim.fn.expand('<cword>') })<cr>";
      }

      # Wrap toggle
      {
        mode = "n";
        key = "<leader>tw";
        action = "<cmd>set wrap!<CR>";
        desc = "Toggle wrap";
      }

      # Conform
      {
        mode = "n";
        key = "<leader>co";
        action = "<cmd>ConformInfo<CR>";
      }
    ];
  };
}
