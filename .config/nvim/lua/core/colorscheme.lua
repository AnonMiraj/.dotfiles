local commands = {
  "catppuccin", "zengarden", "tokyonight", "pompeii", "mellow",
  "rose-pine", "gruvbox-material", "everforest", "onehalflight",
  "onelight", "kanagawa", "melange", "PaperColor", "vscode", "edge",
  "scheakur", "lightning", "atom", "pyte", "solarized","lushwal"
}

local function write_to_file(filename, value)
  local file = io.open(vim.fn.expand(filename), 'w')
  if file then
    file:write(tostring(value))
    file:close()
  end
end

local function read_file(filename)
  local file = io.open(vim.fn.expand(filename), 'r')
  if file then
    local content = file:read("*all")
    file:close()
    return content
  end
  return nil
end

local function display_notification(message)
  os.execute("notify-send '" .. message .. "'")
end

local currentCommandIndex = tonumber(read_file("~/.cache/nvim/color.txt")) or 1
local dark = read_file("~/.cache/nvim/dark.txt") == "1"

vim.cmd("colorscheme " .. commands[currentCommandIndex])
vim.cmd("set background=" .. (dark and "dark" or "light"))

local function switch_color(offset)
  currentCommandIndex = (currentCommandIndex + offset - 1) % #commands + 1
  vim.cmd("colorscheme " .. commands[currentCommandIndex])
  display_notification("Switched to " .. commands[currentCommandIndex])
  write_to_file("~/.cache/nvim/color.txt", currentCommandIndex)
end

function NextColor()
  switch_color(1)
end

function PrevColor()
  switch_color(-1)
end

function Toggle_theme()
  dark = not dark
  vim.cmd("set background=" .. (dark and "dark" or "light"))
  write_to_file("~/.cache/nvim/dark.txt", dark and "1" or "0")
end

local function check_dark_mode()
  local current_dark = read_file("~/.cache/nvim/dark.txt")
  if current_dark and current_dark ~= (dark and "1" or "0") then
    dark = not dark
    vim.cmd("set background=" .. (dark and "dark" or "light"))
  end
end

vim.loop.new_timer():start(2000, 2000, vim.schedule_wrap(check_dark_mode))
if commands[currentCommandIndex]=="lushwal" then
        vim.cmd("silent LushwalCompile")
end

-- Define the keybindings
vim.api.nvim_set_keymap('n', '<F6>', ':lua PrevColor()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F7>', ':lua Toggle_theme()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F8>', ':lua NextColor()<CR>', { noremap = true, silent = true })
