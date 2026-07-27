{
  config,
  pkgs,
  lib,
  ...
}: {
  home.sessionVariables.PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";

  xdg.configFile."python/pythonrc".text = ''
    import readline
    from math import *
    import rlcompleter
    import atexit
    import os

    histfile = os.path.expanduser("~/.python_history")

    if os.path.exists(histfile):
        readline.read_history_file(histfile)

    atexit.register(readline.write_history_file, histfile)

    readline.set_history_length(1000)
    readline.parse_and_bind("tab: complete")
  '';
}
