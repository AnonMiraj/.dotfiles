{ config, pkgs, inputs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
  vicinae-lib = inputs.vicinae.lib.${system};

  jellyfin-ext = vicinae-lib.mkVicinaeExtension {
    pname = "vicinae-extension-jellyfin-browser";
    src = inputs.jellyfin-vicinae;
    npmFlags = [ "--legacy-peer-deps" ];
  };
in {
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true; # default: false
      environment = {
        USE_LAYER_SHELL = "1";
      };
    };
    settings = {
      close_on_focus_loss = false;
      consider_preedit = true;
      pop_to_root_on_close = true;
      favicon_service = "twenty";
      search_files_in_root = true;
      font = {
        normal = {
          size = 12;
          family = "Maple Nerd Font";
        };
      };
      theme = {
        light = {
          name = "noctalia";
          icon_theme = "default";
        };
        dark = {
          name = "noctalia";
          icon_theme = "default";
        };
      };
      launcher_window = {
        opacity = 0.98;
        layer_shell = {
          enabled = true;
          layer = "overlay";
        };
      };
      providers = {
        applications = {
          preferences = {
            paths = [
              "${config.home.homeDirectory}/.local/share/applications"
            ];
          };
        };
        clipboard = {
          preferences = {
            monitoring = true;
          };
        };
      };
    };
    extensions = with inputs.vicinae-extensions.packages.${system}; [
      nix
      power-profile
      jellyfin-ext
    ];
  };
}
