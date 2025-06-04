return {
  'goerz/jupytext.nvim',
  version = '0.2.0',
  lazy = false,
  opts = {
    jupytext = 'jupytext',
    format = "markdown",
    update = true,
    sync_patterns = { '*.md', '*.py', '*.jl', '*.R', '*.Rmd', '*.qmd' },
    autosync = true,
    handle_url_schemes = true,
  }

}
