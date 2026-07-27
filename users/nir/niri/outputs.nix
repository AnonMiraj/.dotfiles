{...}: {
  programs.niri.settings = {
    outputs = {
      "HDMI-A-1" = {
        mode = {
          width = 2560;
          height = 1440;
          refresh = 144.0;
        };
        scale = 1;
        position = {
          x = 0;
          y = 0;
        };
      };
      "eDP-1" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 144.003;
        };
        scale = 1;
        position = {
          x = 2560;
          y = 0;
        };
      };
    };

    workspaces = {
      "browser" = {open-on-output = "eDP-1";};
      "chat" = {open-on-output = "eDP-1";};
    };
  };
}
