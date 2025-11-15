-- float16_viewer.lua
-- A Neovim plugin to convert between float16 numbers and their hexadecimal representations.
-- Enhanced version with improved error handling, visual feedback, and additional features.

local M = {}
local ns = vim.api.nvim_create_namespace("float16_viewer")
local enabled = false
local auto_update = false

-- Check if bit library is available, with fallback implementations
local bit
local has_bit_lib, bit_lib = pcall(require, "bit")
if has_bit_lib then
  bit = bit_lib
else
  -- Fallback bit operations for systems without bit library
  bit = {
    band = function(a, b)
      local result = 0
      local bit_pos = 1
      while a > 0 or b > 0 do
        if (a % 2 == 1) and (b % 2 == 1) then
          result = result + bit_pos
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit_pos = bit_pos * 2
      end
      return result
    end,

    bor = function(a, b)
      local result = 0
      local bit_pos = 1
      while a > 0 or b > 0 do
        if (a % 2 == 1) or (b % 2 == 1) then
          result = result + bit_pos
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit_pos = bit_pos * 2
      end
      return result
    end,

    lshift = function(a, n)
      return math.floor(a * (2 ^ n))
    end,

    rshift = function(a, n)
      return math.floor(a / (2 ^ n))
    end,
  }
end

-- Configuration
M.config = {
  highlight_group = "Comment",
  auto_update_on_cursor_move = false,
  show_detailed_breakdown = true,
  format_precision = 8,
}

-- Set up configuration
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Sync the auto_update variable with config
  auto_update = M.config.auto_update_on_cursor_move
end

--[[
-- Conversion from Lua number (double-precision) to float16 (half-precision).
-- This function correctly implements the IEEE 754-2008 standard for half-precision floats.
-- It handles special cases like Infinity, NaN, and subnormal numbers.
--]]
local function to_float16_bits(num)
  -- Handle special cases
  if num ~= num then
    return "0x7C01", "NaN", { sign = 0, exponent = 31, fraction = 1 }
  end
  if num == math.huge then
    return "0x7C00", "+inf", { sign = 0, exponent = 31, fraction = 0 }
  end
  if num == -math.huge then
    return "0xFC00", "-inf", { sign = 1, exponent = 31, fraction = 0 }
  end
  if num == 0 then
    return "0x0000", "0", { sign = 0, exponent = 0, fraction = 0 }
  end
  if num == -0 then
    return "0x8000", "-0", { sign = 1, exponent = 0, fraction = 0 }
  end

  local sign_bit = (num < 0) and 1 or 0
  num = math.abs(num)

  -- Use math.frexp to reliably get the mantissa and exponent
  local m, e = math.frexp(num)

  -- Adjust mantissa to [1.0, 2.0) range
  if m ~= 0 then
    m = m * 2
    e = e - 1
  end

  local exponent_bits, frac_bits
  local biased_exponent = e + 15

  if biased_exponent >= 31 then
    -- Exponent overflow, represent as infinity
    exponent_bits = 31
    frac_bits = 0
  elseif biased_exponent <= 0 then
    -- Subnormal number
    exponent_bits = 0
    -- Calculate subnormal fraction
    local shift = 1 - biased_exponent
    if shift <= 24 then                     -- Prevent excessive shifting
      frac_bits = math.floor(m * (2 ^ 10) / (2 ^ shift) + 0.5)
      frac_bits = math.min(frac_bits, 1023) -- Clamp to 10 bits
    else
      frac_bits = 0                         -- Underflow to zero
    end
  else
    -- Normal number
    exponent_bits = biased_exponent
    frac_bits = math.floor((m - 1.0) * 1024 + 0.5)
    frac_bits = math.min(frac_bits, 1023) -- Clamp to 10 bits
  end

  -- Combine the bits: Sign (1) | Exponent (5) | Fraction (10)
  local bits = bit.bor(
    bit.lshift(sign_bit, 15),
    bit.bor(bit.lshift(exponent_bits, 10), frac_bits)
  )

  local hex_str = string.format("0x%04X", bits)
  local value_str = string.format("%." .. M.config.format_precision .. "g",
    sign_bit == 1 and -num or num)

  return hex_str, value_str, {
    sign = sign_bit,
    exponent = exponent_bits,
    fraction = frac_bits,
    raw_bits = bits
  }
end

--[[
-- Conversion from float16 bits to a Lua number.
-- This function decodes the 16 bits according to the IEEE 754-2008 standard.
--]]
local function from_float16_bits(bits)
  if bits > 0xFFFF then
    return nil, "Invalid: exceeds 16 bits"
  end

  local sign_bit = bit.rshift(bits, 15)
  local exponent_bits = bit.band(bit.rshift(bits, 10), 0x1F)
  local frac_bits = bit.band(bits, 0x3FF)

  local value
  local value_type = "normal"

  if exponent_bits == 0 then
    if frac_bits == 0 then
      -- Zero
      value = 0.0
      value_type = "zero"
    else
      -- Subnormal number
      value = (frac_bits / 1024.0) * (2 ^ (1 - 15))
      value_type = "subnormal"
    end
  elseif exponent_bits == 0x1F then
    -- Special case: Infinity or NaN
    if frac_bits == 0 then
      value = math.huge
      value_type = "infinity"
    else
      return "NaN", "NaN", {
        sign = sign_bit,
        exponent = exponent_bits,
        fraction = frac_bits,
        type = "nan"
      }
    end
  else
    -- Normal number
    local e_val = exponent_bits - 15
    value = (1.0 + frac_bits / 1024.0) * (2 ^ e_val)
    value_type = "normal"
  end

  if sign_bit == 1 then
    value = -value
  end

  local value_str = string.format("%." .. M.config.format_precision .. "g", value)

  return value_str, value_type, {
    sign = sign_bit,
    exponent = exponent_bits,
    fraction = frac_bits,
    type = value_type,
    raw_bits = bits
  }
end

-- Get the word under cursor with better parsing
local function get_word_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Find word boundaries
  local start_col = col
  local end_col = col

  -- Expand to include hex prefixes and number suffixes
  while start_col > 0 do
    local char = line:sub(start_col, start_col)
    if char:match("[%w%.xX]") then
      start_col = start_col - 1
    else
      start_col = start_col + 1
      break
    end
  end

  while end_col <= #line do
    local char = line:sub(end_col + 1, end_col + 1)
    if char:match("[%w%.uUlLfF]") then
      end_col = end_col + 1
    else
      break
    end
  end

  if start_col <= end_col then
    return line:sub(start_col, end_col), start_col - 1, end_col
  end

  return vim.fn.expand("<cword>"), nil, nil
end

-- Clear virtual text
local function clear_virtual_text()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

-- Display conversion result
local function display_conversion(word, start_col, end_col)
  -- Strip C/C++ style suffixes
  local clean_word = word:gsub("[uUlLfF]+$", "")

  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local text_to_display
  local details = {}

  if clean_word:match("^0[xX]") then
    -- Interpret as raw float16 bits (hex string)
    local bits = tonumber(clean_word, 16)
    if not bits then
      text_to_display = " → Error: Invalid hex number"
    else
      local val, val_type, components = from_float16_bits(bits)
      if val == nil then
        text_to_display = " → Error: " .. (val_type or "Unknown error")
      else
        text_to_display = string.format(" → Dec: %s", val)
        if M.config.show_detailed_breakdown and components then
          table.insert(details, string.format("Type: %s", components.type))
          if components.type ~= "nan" then
            table.insert(details, string.format("Sign: %d, Exp: %d, Frac: %d",
              components.sign, components.exponent, components.fraction))
          end
        end
      end
    end
  else
    -- Interpret as decimal number
    local num = tonumber(clean_word)
    if not num then
      text_to_display = ""
    else
      local hex_str, val_str, components = to_float16_bits(num)
      text_to_display = string.format(" → Hex: %s", hex_str)
      if M.config.show_detailed_breakdown and components then
        table.insert(details, string.format("Sign: %d, Exp: %d, Frac: %d",
          components.sign, components.exponent, components.fraction))
      end
    end
  end

  -- Create virtual text
  local virt_text = { { text_to_display, M.config.highlight_group } }

  -- Add details if available
  if #details > 0 then
    for _, detail in ipairs(details) do
      table.insert(virt_text, { " (" .. detail .. ")", "NonText" })
    end
  end

  -- Display the result as virtual text
  vim.api.nvim_buf_set_extmark(0, ns, row, -1, {
    virt_text = virt_text,
    hl_mode = "combine",
  })
end

-- Update conversion display
local function update_display()
  if not enabled then return end

  clear_virtual_text()

  local word, start_col, end_col = get_word_under_cursor()
  if word and word ~= "" then
    display_conversion(word, start_col, end_col)
  end
end

-- Toggle the viewer on and off
function M.toggle()
  enabled = not enabled
  clear_virtual_text()

  if not enabled then
    print("Float16 viewer: OFF")
    if auto_update then
      M.disable_auto_update()
    end
    return
  end

  print("Float16 viewer: ON")
  update_display()
end

-- Enable auto-update on cursor movement
function M.enable_auto_update()
  if auto_update then return end

  auto_update = true
  M.config.auto_update_on_cursor_move = true

  -- Set up autocommands for cursor movement
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = vim.api.nvim_create_augroup("Float16ViewerAuto", { clear = true }),
    callback = function()
      if enabled then
        update_display()
      end
    end,
  })

  print("Float16 viewer: Auto-update enabled")
end

-- Disable auto-update
function M.disable_auto_update()
  auto_update = false
  M.config.auto_update_on_cursor_move = false

  -- Clear autocommands
  pcall(vim.api.nvim_del_augroup_by_name, "Float16ViewerAuto")

  print("Float16 viewer: Auto-update disabled")
end

-- Toggle auto-update
function M.toggle_auto_update()
  if auto_update then
    M.disable_auto_update()
  else
    M.enable_auto_update()
  end
end

-- Convert current word and copy to clipboard
function M.convert_and_copy()
  local word, _, _ = get_word_under_cursor()
  if not word or word == "" then
    print("No word under cursor")
    return
  end

  local clean_word = word:gsub("[uUlLfF]+$", "")
  local result

  if clean_word:match("^0[xX]") then
    local bits = tonumber(clean_word, 16)
    if bits then
      local val, _, _ = from_float16_bits(bits)
      result = val
    end
  else
    local num = tonumber(clean_word)
    if num then
      local hex_str, _, _ = to_float16_bits(num)
      result = hex_str
    end
  end

  if result then
    vim.fn.setreg('+', result)
    print("Copied to clipboard: " .. result)
  else
    print("Failed to convert: " .. word)
  end
end

-- Show status
function M.status()
  local status = {
    "Float16 Viewer Status:",
    "  Enabled: " .. (enabled and "ON" or "OFF"),
    "  Auto-update: " .. (auto_update and "ON" or "OFF"),
    "  Highlight group: " .. M.config.highlight_group,
  }
  print(table.concat(status, "\n"))
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command("Float16Toggle", M.toggle, {
    desc = "Toggle float16 viewer"
  })

  vim.api.nvim_create_user_command("Float16Auto", M.toggle_auto_update, {
    desc = "Toggle auto-update on cursor move"
  })

  vim.api.nvim_create_user_command("Float16Copy", M.convert_and_copy, {
    desc = "Convert current word and copy to clipboard"
  })

  vim.api.nvim_create_user_command("Float16Status", M.status, {
    desc = "Show float16 viewer status"
  })
end

-- Initialize the plugin
function M.init()
  M.setup_commands()
end

return M
