{
  config,
  pkgs,
  lib,
  ...
}: {
  xdg.configFile = {
    "niri/scripts/kitty-sessions.sh" = {
      source = ./scripts/kitty-sessions.sh;
      executable = true;
    };
    "niri/scripts/phoneMirror" = {
      source = ./scripts/phoneMirror;
      executable = true;
    };
  };
}
