{...}: {
  xdg.configFile = {
    "hypr/scripts/kitty-sessions.sh" = {
      source = ../scripts/kitty-sessions.sh;
      executable = true;
    };
    "hypr/scripts/phoneMirror" = {
      source = ../scripts/phoneMirror;
      executable = true;
    };
  };
}
