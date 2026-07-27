{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.nvf.settings.vim = {
    # ── which-key (built-in) ──────────────────────────────────────
    binds.whichKey.enable = true;

    # ── lspkind (built-in) ────────────────────────────────────────
    lsp.enable = true;
    lsp.lspkind.enable = true;

    # ── Formatter (conform-nvim) ──────────────────────────────────
    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        formatters_by_ft = {
          bash = ["shfmt"];
          fish = ["fish_indent"];
          lua = ["stylua"];
          python = ["black"];
          rust = ["rustfmt"];
          nix = ["alejandra"];
          go = ["golines"];
          c = ["clang-format"];
          cpp = ["clang-format"];
        };
      };
    };

    # ── nvim-cmp sources + plugins ───────────────────────────────
    autocomplete.nvim-cmp = {
      sources = {
        nvim-lsp = "[LSP]";
        luasnip = lib.mkForce "[SNIP]";
        buffer = "[BUF]";
        path = "[PATH]";
        nvim-lua = "[LUA]";
        nvim-lsp-signature-help = null;
      };
      sourcePlugins = with pkgs.vimPlugins; [
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-nvim-lua
        cmp-cmdline
        cmp_luasnip
      ];
      mappings = {
        complete = "<C-Space>";
        confirm = "<CR>";
        next = "<Tab>";
        previous = "<S-Tab>";
        close = "<C-e>";
        scrollDocsUp = "<C-d>";
        scrollDocsDown = "<C-f>";
      };
    };

    # ── Extra plugins (not built into nvf) ───────────────────────
    extraPlugins = {
      # alabaster.nvim — default theme
      alabaster = {
        package = pkgs.vimPlugins.alabaster-nvim;
        setup = ''
          vim.cmd("colorscheme alabaster")
        '';
      };

      # barbar.nvim — buffer tabs
      barbar = {
        package = pkgs.vimPlugins.barbar-nvim;
        setup = ''
          require("barbar").setup({
            animation = true,
            insert_at_start = false,
            sidebar_filetypes = { ["oil"] = { event = "BufWipeout" } },
          })
        '';
      };

      # fff.nvim — fuzzy finder (replaces telescope)
      fff = {
        package = pkgs.vimPlugins.fff-nvim;
        setup = ''
          require("fff").setup({
            prompt = "🪿 ",
            title = "FFFiles",
            grep = { smart_case = true, modes = { "plain", "regex", "fuzzy" } },
          })
        '';
      };

      # hlchunk.nvim — indent chunk highlight
      hlchunk = {
        package = pkgs.vimPlugins.hlchunk-nvim;
        setup = ''
          require("hlchunk").setup({
            chunk = {
              enable = true,
              chars = { horizontal_line = "─", vertical_line = "│", left_top = "╭", left_bottom = "╰", right_arrow = ">" },
              style = "#806d9c",
            },
            indent = { enable = false },
            blank = { enable = false },
            line_num = { style = "#806d9c" },
          })
        '';
      };

      # nvim-hlslens — search highlight lens
      hlslens = {
        package = pkgs.vimPlugins.nvim-hlslens;
        setup = ''
          require("hlslens").setup()
        '';
      };

      # nvim-lastplace — reopen at last position
      lastplace = {
        package = pkgs.vimPlugins.nvim-lastplace;
        setup = ''
          require("nvim-lastplace").setup({
            lastplace_ignore_buftype = { "terminal", "help", "Trouble" },
            lastplace_ignore_filetype = { "terminal", "help", "Trouble" },
            lastplace_open_folds = true,
          })
        '';
      };

      # nvim-treesitter-context — function context
      treesitter-context = {
        package = pkgs.vimPlugins.nvim-treesitter-context;
        setup = ''
          require("treesitter-context").setup({
            enable = true, throttle = true, max_lines = 0,
            patterns = { default = { "class", "function", "method" } },
          })
        '';
      };

      # render-markdown.nvim — markdown rendering
      render-markdown = {
        package = pkgs.vimPlugins.render-markdown-nvim;
        setup = ''
          require("render-markdown").setup({})
        '';
      };

      # image.nvim config (package already in utility.images)
      # We add the config here since utility.images just provides the pkg
      image-config = {
        after = ["images"];
        setup = ''
          require("image").setup({
            backend = "kitty",
            integrations = {
              markdown = { enabled = true, clear_in_insert_mode = false, download_remote_images = true, only_render_image_at_cursor = false, filetypes = { "markdown", "vimwiki" } },
              neorg = { enabled = true, clear_in_insert_mode = false, download_remote_images = true, only_render_image_at_cursor = false, filetypes = { "norg" } },
              typst = { enabled = false },
            },
            max_width = 100,
            max_height = 12,
            max_height_window_percentage = math.huge,
            max_width_window_percentage = math.huge,
            window_overlap_clear_enabled = true,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
            kitty_method = "normal",
          })
        '';
      };

      # competitest.nvim — competitive programming helper
      competitest = {
        package = pkgs.vimPlugins.competitest-nvim;
        setup = ''
          require("competitest").setup({
            compile_command = {
              c = { exec = "gcc", args = { "-DALGOAT", "-Wall", "$(FNAME)", "-o", "$(FNOEXT).o" } },
              cpp = { exec = "g++", args = { "-DALGOAT", "-Wall", "$(FNAME)", "-o", "$(FNOEXT).o", "-g" } },
              haskell = { exec = "ghc", args = { "-dynamic", "$(FNAME)", "-o", "$(FNOEXT).ex" } },
              py = { exec = "python", args = { "$(FNAME)" } },
              rust = { exec = "rustc", args = { "$(FNAME)", "--crate-name", "test" } },
              java = { exec = "javac", args = { "$(FNAME)" } },
            },
            run_command = {
              c = { exec = "./$(FNOEXT).o" },
              cpp = { exec = "./$(FNOEXT).o" },
              haskell = { exec = "./$(FNOEXT).ex" },
              rust = { exec = "./test" },
              python = { exec = "python", args = { "$(FNAME)" } },
              java = { exec = "java", args = { "$(FNOEXT)" } },
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
          })
        '';
      };

      # fconv.nvim — float↔hex converter
      fconv = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "fconv-nvim";
          src = inputs.fconv-nvim;
        };
        setup = ''
          require("fconv").setup({
            keymaps = {
              toggle = "gs",
              copy = "gy",
              inspect = "gl",
            },
          })
        '';
      };
    };

    # ── Extra lua config (DAG entries) ────────────────────────────
    luaConfigRC = {
      # hlslens — keymaps for search highlight
      hlslens-mappings = ''
        local kopts = { noremap = true, silent = true }
        vim.api.nvim_set_keymap('n', 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
        vim.api.nvim_set_keymap('n', 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
        vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
        vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
        vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
        vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
        vim.api.nvim_set_keymap('n', '<Leader>l', '<Cmd>noh<CR>', kopts)
      '';

      # Markdown ftplugin — paste url as markdown link
      markdown-ftplugin = ''
        local function escape_markdown(text)
          return text:gsub("([%%[%%]])", "\\%1")
        end

        local function fetch_title(url)
          local cmd = {
            "curl", "-Ls", "--compressed", "--connect-timeout", "1",
            "--max-time", "2", "--range", "0-50000", "-A", "", url,
          }
          local html = vim.fn.system(cmd)
          local og_title = html:match('<meta%s+property=["\']og:title["\']%s+content=["\'](.-)["\']')
          if og_title and og_title ~= "" then return og_title end
          local page_title = html:match("<title>(.-)</title>")
          if page_title then return page_title:match("^%s*(.-)%s*$") end
          return nil
        end

        function paste_url_as_markdown()
          local clip = (vim.fn.getreg("+") or ""):match("^%s*(.-)%s*$")
          if not clip or not clip:match("^https?://%S+$") then
            return vim.api.nvim_feedkeys("p", "n", false)
          end
          local title = fetch_title(clip)
          if not title then
            print("Could not fetch title for " .. clip)
            return vim.api.nvim_feedkeys("p", "n", false)
          end
          local md = string.format("[%s](%s)", escape_markdown(title), clip)
          vim.api.nvim_put({ md }, "l", true, true)
        end

        function replace_url_with_title()
          local url = vim.fn.expand("<cWORD>")
          if not url:match("^https?://") then return end
          local title = fetch_title(url)
          if not title then print("Could not fetch title for " .. url) return end
          local line = vim.api.nvim_get_current_line()
          local s, e = line:find(vim.pesc(url))
          if not s then return end
          local row = vim.api.nvim_win_get_cursor(0)[1]
          local md = string.format("[%s](%s)", escape_markdown(title), url)
          vim.api.nvim_buf_set_text(0, row - 1, s - 1, row - 1, e, { md })
        end

        vim.keymap.set("n", "p", paste_url_as_markdown, { desc = "Paste URL as [title](URL)" })
        vim.keymap.set("n", "<leader>ml", replace_url_with_title, { desc = "Replace URL with [title](URL)" })
      '';

      # Yank highlight
      yank-highlight = ''
        vim.api.nvim_create_autocmd("TextYankPost", {
          pattern = "*",
          callback = function() vim.highlight.on_yank() end,
        })
      '';

      # cmp — lspkind formatting override
      cmp-format = ''
        local lspkind = require("lspkind")
        lspkind.init({
          symbol_map = {
            Text = "", Method = "ƒ", Function = "",
            Constructor = "", Variable = "[]", Property = "",
            Color = "", File = "", EnumMember = "  ",
            Constant = "", Struct = "  ",
          },
        })
      '';

      # competitest — keymaps
      competitest-keymaps = ''
        local kopts = { noremap = true, silent = true }

        vim.api.nvim_set_keymap(
          "n",
          "<leader>rc",
          "<cmd>CompetiTest receive contest<CR>",
          vim.tbl_extend("force", kopts, { desc = "receive contest" })
        )
        vim.api.nvim_set_keymap(
          "n",
          "<leader>rp",
          "<cmd>CompetiTest receive problem<CR>",
          vim.tbl_extend("force", kopts, { desc = "receive problem" })
        )
        vim.api.nvim_set_keymap(
          "n",
          "<leader>ra",
          "<cmd>CompetiTest add_testcase<CR>",
          vim.tbl_extend("force", kopts, { desc = "add testcase" })
        )
        vim.api.nvim_set_keymap(
          "n",
          "<leader>re",
          "<cmd>CompetiTest edit_testcase<CR>",
          vim.tbl_extend("force", kopts, { desc = "edit testcase" })
        )
        vim.api.nvim_set_keymap(
          "n",
          "<leader>rr",
          "<cmd>CompetiTest run<CR>",
          vim.tbl_extend("force", kopts, { desc = "run code" })
        )
      '';
    };
  };
}
