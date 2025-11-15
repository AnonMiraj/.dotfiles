local function escape_markdown(text)
  return text:gsub("([%[%]])", "\\%1")
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
  if page_title then
    return page_title:match("^%s*(.-)%s*$")
  end

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
  if not url:match("^https?://") then
    return
  end

  local title = fetch_title(url)
  if not title then
    print("Could not fetch title for " .. url)
    return
  end

  local line = vim.api.nvim_get_current_line()
  local s, e = line:find(vim.pesc(url))
  if not s then return end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  local md = string.format("[%s](%s)", escape_markdown(title), url)

  vim.api.nvim_buf_set_text(0, row - 1, s - 1, row - 1, e, { md })
end

vim.keymap.set("n", "p", paste_url_as_markdown, { desc = "Paste URL as [title](URL)" })
vim.keymap.set("n", "<leader>ml", replace_url_with_title, { desc = "Replace URL with [title](URL)" })
