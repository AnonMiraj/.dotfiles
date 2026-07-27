{...}: {
  programs.niri.settings.window-rules = [
    # Global defaults — corner radius + clip + background blur
    {
      matches = [{}];
      geometry-corner-radius = {
        top-left = 12.0;
        top-right = 12.0;
        bottom-left = 12.0;
        bottom-right = 12.0;
      };
      clip-to-geometry = true;
      draw-border-with-background = false;
      background-effect = {
        blur = true;
        xray = true;
      };
    }

    # Urgent windows — red shadow
    {
      matches = [{is-urgent = true;}];
      shadow.color = "#7d0d2d70";
    }


    # SubMiner overlay — floating above mpv
    {
      matches = [{app-id = "^SubMiner$";}];
      open-floating = true;
      background-effect = {
        blur = false;
        xray = false;
      };
    }
    # Telegram
    {
      matches = [{app-id = "^org\\.telegram\\.desktop$";}];
      geometry-corner-radius = {
        top-left = 6.0;
        top-right = 6.0;
        bottom-left = 6.0;
        bottom-right = 6.0;
      };
      open-on-workspace = "chat";
    }
    {
      matches = [
        {
          app-id = "^org\\.telegram\\.desktop$";
          title = "^Media viewer$";
        }
      ];
      open-fullscreen = false;
      open-floating = true;
    }

    # Vencord/Discord
    {
      matches = [{app-id = "^vesktop$";}];
      open-on-workspace = "chat";
    }
    {
      matches = [{app-id = "^vesktop$";} {app-id = "^com\\.discordapp\\.Discord$";}];
      default-column-width = {proportion = 0.66667;};
    }

    # Obsidian — fixed width
    {
      matches = [{app-id = "^obsidian$";}];
      default-column-width = {fixed = 1000;};
    }

    # nvim — wider column
    {
      matches = [{title = "^nvim.*";}];
      default-column-width = {proportion = 0.66667;};
    }

    # TheFarmerWasReplaced — floating
    {
      matches = [{title = "^TheFarmerWasReplaced$";}];
      open-floating = true;
    }

    # Window cast target — colored decorations
    {
      matches = [{is-window-cast-target = true;}];
      focus-ring = {
        active.color = "#f38ba8";
        inactive.color = "#7d0d2d";
      };
      border.inactive.color = "#7d0d2d";
      shadow.color = "#7d0d2d70";
      tab-indicator = {
        active.color = "#f38ba8";
        inactive.color = "#7d0d2d";
      };
    }

    # GNOME apps — corner radius + clip
    {
      matches = [{app-id = "^org\\.gnome\\..*";}];
      draw-border-with-background = false;
      geometry-corner-radius = {
        top-left = 12.0;
        top-right = 12.0;
        bottom-left = 12.0;
        bottom-right = 12.0;
      };
      clip-to-geometry = true;
    }

    # Settings apps
    {
      matches = [
        {app-id = "^gnome-control-center$";}
        {app-id = "^pavucontrol$";}
        {app-id = "^nm-connection-editor$";}
      ];
      default-column-width = {proportion = 0.5;};
    }

    # xdg-desktop-portal — floating
    {
      matches = [{app-id = "^xdg-desktop-portal$";}];
      open-floating = true;
    }

    # General opacity
    {
      matches = [{}];
      opacity = 0.95;
    }

    # Kitty — full opacity
    {
      matches = [{app-id = "^kitty$";}];
      opacity = 1.0;
    }

    # MPV — floating, VRR, opaque
    {
      matches = [{app-id = "^mpv$";}];
      variable-refresh-rate = true;
      default-column-width = {};
      # open-floating = true;
      open-maximized-to-edges =true;
      open-on-output = "HDMI-A-1";
      opacity = 1.0;
      
    }

    # Quickshell (DMS) — floating
    {
      matches = [{app-id = "^org\\.quickshell$";}];
      open-floating = true;
    }

    # File chooser — floating, sized
    {
      matches = [{app-id = "^file_chooser$";}];
      open-floating = true;
      default-column-width = {proportion = 0.6;};
      default-window-height = {proportion = 0.6;};
      default-floating-position = {
        relative-to = "top";
        x = 0;
        y = 0;
      };
      baba-is-float = true;
      scroll-factor = 0.75;
    }

    # Zen browser + kitty — no CSD border background
    {
      matches = [{app-id = "^zen-beta$";} {app-id = "^kitty$";}];
      draw-border-with-background = false;
    }

    # Zen browser — browser workspace, maximized
    {
      matches = [{app-id = "^zen-beta$";}];
      open-on-workspace = "browser";
      open-maximized = true;
      default-column-width = {proportion = 0.5;};
    }
    {
      matches = [
        {
          app-id = "^zen-beta$";
          title = "^Picture-in-Picture$";
        }
      ];
      open-floating = true;
    }
  ];
}
