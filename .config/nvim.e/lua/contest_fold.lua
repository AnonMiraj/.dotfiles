
local M = {}

function M.fold_contest_lines(lnum)
  local line = vim.fn.getline(lnum)
  
  -- Check if the current line starts with "// Contest: "
  if line:match("^%s*// Contest:") then
    -- Return ">1" to fold only the current line
    return "="
  end
  
  -- Return '=' for all other lines to maintain existing folds
  return ">1"
end

return M

