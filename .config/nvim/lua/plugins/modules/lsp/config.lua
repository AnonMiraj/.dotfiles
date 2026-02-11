-- [[ Modern LSP Configuration for Nvim 0.11+ ]]

-- 1. Global Diagnostic Configuration
vim.diagnostic.config({
  virtual_text = { prefix = '●' },
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    style = 'minimal',
    border = 'rounded',
    source = true,
    header = '',
    prefix = '',
  },
  -- Modern way to set signs in Nvim 0.10+
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN]  = " ",
      [vim.diagnostic.severity.HINT]  = "󰌵 ",
      [vim.diagnostic.severity.INFO]  = " ",
    },
  },
})

-- 2. Modern LspAttach Autocommand
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local bufnr = ev.buf

    local nmap = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
    end

    -- -- Built-in LSP mappings
    -- nmap('gd', vim.lsp.buf.definition, 'Goto Definition')
    -- nmap('gr', vim.lsp.buf.references, 'Find References')
    -- nmap('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
    -- nmap('<leader>rn', vim.lsp.buf.rename, 'Rename Symbol')
    -- nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    --
    -- -- Modern Diagnostic Navigation (Nvim 0.11+ uses jump)
    -- nmap(']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, 'Next Diagnostic')
    -- nmap('[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'Prev Diagnostic')
    -- nmap('<leader>dd', vim.diagnostic.setloclist, 'Open Diagnostics List')
    --
    -- Create local Format command
    vim.api.nvim_buf_create_user_command(bufnr, 'Format', function()
      vim.lsp.buf.format({ async = true })
    end, { desc = 'Format current buffer with LSP' })
  end,
})

-- 3. Capability setup for completion
local capabilities = vim.lsp.protocol.make_client_capabilities()
local status_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if status_ok then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

-- 4. Server Configurations
local servo_path = vim.fn.resolve(os.getenv("HOME") .. "/Documents/servo")
local is_in_servo = vim.fn.getcwd():find(servo_path, 1, true) == 1

-- Shared window configuration for UI elements
local window_config = {
  hover = { border = "rounded" },
  signature_help = { border = "rounded" },
}

local servers = {
  clangd = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=never",
    },
  },

  pylsp = {
    settings = {
      pylsp = {
        plugins = {
          pycodestyle = { maxLineLength = 1250 },
          pylint = { args = { "--errors-only" }, enabled = true },
        },
      },
    },
  },
  html = { filetypes = { 'html', 'twig', 'hbs' } },
  ts_ls = {},
  lua_ls = {
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
        diagnostics = { disable = { 'missing-fields' } },
      },
    },
  },
}

-- Handle Rust specifically for Servo
local rust_config = {}
if is_in_servo then
  vim.notify("LSP: Using Servo project settings", vim.log.levels.INFO)
  rust_config.settings = {
    ['rust-analyzer'] = {
      rustfmt = { overrideCommand = { "./mach", "fmt" } },
      check = { overrideCommand = { "./mach", "clippy", "--message-format=json", "--target-dir", "target/lsp", "--features", "tracing,tracing-perfetto" } },
      cargo = { buildScripts = { overrideCommand = { "./mach", "clippy", "--message-format=json", "--target-dir", "target/lsp", "--features", "tracing,tracing-perfetto" } } },
    },
  }
end
servers.rust_analyzer = rust_config

-- 5. Mason and Initialization
require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = vim.tbl_keys(servers),
})

-- 6. Enable servers using the new Nvim 0.11 API
for server_name, config in pairs(servers) do
  -- Merge capabilities and window settings
  config.capabilities = vim.tbl_deep_extend('force', capabilities, config.capabilities or {})
  config.window = vim.tbl_deep_extend('force', window_config, config.window or {})

  vim.lsp.config(server_name, config)
  vim.lsp.enable(server_name)
end
