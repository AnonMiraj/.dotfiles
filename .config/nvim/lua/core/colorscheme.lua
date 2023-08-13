-- Define your list of commands
local commands = {
  "colorscheme catppuccin",
  "colorscheme zengarden",
  "colorscheme tokyonight ",
  "colorscheme pompeii",
  "colorscheme mellow",
  "colorscheme rose-pine",
  "colorscheme gruvbox-material",
  "colorscheme solarized"

}

-- Function to read the integer value from the file
local function read_integer_from_file()
  local file = io.open(vim.fn.expand("~/.cache/nvim/color.txt"), 'r')
  if file then
    local value = tonumber(file:read('*all'))
    file:close()
    return value
  else
    return nil
  end
end

-- Function to write the integer value to the file
local function write_integer_to_file(value)
  local file = io.open(vim.fn.expand("~/.cache/nvim/color.txt"), 'w')
  if file then
    file:write(tostring(value))
    file:close()
  end
end

local function display_notification(message)
  os.execute("notify-send '" .. message .. "'")
end

-- Read the integer value from the file or set a default value
local CurrentCommandIndex = read_integer_from_file() or 1
vim.cmd(commands[CurrentCommandIndex])

-- Define the keybindings
vim.api.nvim_set_keymap('n', '<F6>', ':lua PrevColor()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F8>', ':lua NextColor()<CR>', { noremap = true, silent = true })

function NextColor()
  CurrentCommandIndex = (CurrentCommandIndex % #commands) + 1
  vim.cmd(commands[CurrentCommandIndex])
  -- print(commands[CurrentCommandIndex])
  display_notification("Switched to " .. commands[CurrentCommandIndex])
  write_integer_to_file(CurrentCommandIndex)
end

function PrevColor()
  CurrentCommandIndex = (CurrentCommandIndex - 2) % #commands + 1
  vim.cmd(commands[CurrentCommandIndex])
  display_notification("Switched to " .. commands[CurrentCommandIndex])
  write_integer_to_file(CurrentCommandIndex)
end
