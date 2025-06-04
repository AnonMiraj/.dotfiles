return {
  'RedsXDD/neopywal.nvim',
  name = 'neopywal',
  lazy = false,
  priority = 1000,
  opts = {
    use_palette = 'wallust',
    -- transparent_background = true,
  },
  init = function()
    handle = io.popen("gsettings get org.gnome.desktop.interface color-scheme")
    if handle then
      local result = handle:read("*a")
      handle:close()
      if result:match("dark") then
        vim.cmd.colorscheme("neopywal-dark")
      else
        vim.cmd.colorscheme("neopywal-light")
      end
    end
  end,
}
