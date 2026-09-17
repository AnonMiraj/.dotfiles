{...}: {
  wayland.windowManager.hyprland.settings = {
    # Curves and animations follow the shipped example/hyprland.lua.
    curve = [
      {
        _args = [
          "easeOutQuint"
          {
            type = "bezier";
            points = [[0.23 1.0] [0.32 1.0]];
          }
        ];
      }
      {
        _args = [
          "easeInOutCubic"
          {
            type = "bezier";
            points = [[0.65 0.05] [0.36 1.0]];
          }
        ];
      }
      {
        _args = [
          "linear"
          {
            type = "bezier";
            points = [[0.0 0.0] [1.0 1.0]];
          }
        ];
      }
      {
        _args = [
          "almostLinear"
          {
            type = "bezier";
            points = [[0.5 0.5] [0.75 1.0]];
          }
        ];
      }
      {
        _args = [
          "quick"
          {
            type = "bezier";
            points = [[0.15 0.0] [0.1 1.0]];
          }
        ];
      }
      {
        _args = [
          "easy"
          {
            type = "spring";
            mass = 1.0;
            stiffness = 238.1191;
            dampening = 24.21279333;
          }
        ];
      }
    ];

    animation = [
      {
        leaf = "global";
        enabled = true;
        speed = 10.0;
        bezier = "default";
      }
      {
        leaf = "border";
        enabled = true;
        speed = 5.39;
        bezier = "easeOutQuint";
      }
      {
        leaf = "windows";
        enabled = true;
        speed = 4.79;
        spring = "easy";
      }
      {
        leaf = "windowsIn";
        enabled = true;
        speed = 4.1;
        spring = "easy";
        style = "popin 87%";
      }
      {
        leaf = "windowsOut";
        enabled = true;
        speed = 1.49;
        bezier = "linear";
        style = "popin 87%";
      }
      {
        leaf = "fadeIn";
        enabled = true;
        speed = 1.73;
        bezier = "almostLinear";
      }
      {
        leaf = "fadeOut";
        enabled = true;
        speed = 1.46;
        bezier = "almostLinear";
      }
      {
        leaf = "fade";
        enabled = true;
        speed = 3.03;
        bezier = "quick";
      }
      {
        leaf = "layers";
        enabled = true;
        speed = 3.81;
        bezier = "easeOutQuint";
      }
      {
        leaf = "layersIn";
        enabled = true;
        speed = 4.0;
        bezier = "easeOutQuint";
        style = "fade";
      }
      {
        leaf = "layersOut";
        enabled = true;
        speed = 1.5;
        bezier = "linear";
        style = "fade";
      }
      {
        leaf = "fadeLayersIn";
        enabled = true;
        speed = 1.79;
        bezier = "almostLinear";
      }
      {
        leaf = "fadeLayersOut";
        enabled = true;
        speed = 1.39;
        bezier = "almostLinear";
      }
      # slidevert: the scrolling layout keeps columns on a vertical tape, so
      # the workspace switch moves on that axis.
      {
        leaf = "workspaces";
        enabled = true;
        speed = 1.94;
        bezier = "almostLinear";
        style = "slidevert";
      }
      {
        leaf = "zoomFactor";
        enabled = true;
        speed = 7.0;
        bezier = "quick";
      }
    ];
  };
}
