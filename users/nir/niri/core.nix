{ config, pkgs, lib, ... }: let
  cfg = config.programs.niri;
in {
  programs.niri.settings = {
    # ── Notifications ──────────────────────────────────────
    config-notification.disable-failed = true;

    # ── Input ──────────────────────────────────────────────
    input = {
      workspace-auto-back-and-forth = true;
      focus-follows-mouse.enable = true;

      keyboard = {
        xkb = {
          layout = "us,ara";
          options = "grp:win_space_toggle, caps:escape , altwin:menu_win";
        };
        track-layout = "window";
        repeat-delay = 255;
        repeat-rate = 40;
        numlock = true;
      };

      touchpad = {
        tap = true;
        natural-scroll = true;
      };
    };

    # ── Layout ─────────────────────────────────────────────
    layout = {
      gaps = 4;
      background-color = "transparent";
      center-focused-column = "never";
      preset-column-widths = [
        {proportion = 0.33333;}
        {proportion = 0.5;}
        {proportion = 0.66667;}
      ];
      default-column-width = {
        proportion = 0.5;
      };

      border = {
        enable = false;
        width = 2;
        active.color = "#707070";
        inactive.color = "#d0d0d0";
        urgent.color = "#cc4444";
      };

      focus-ring = {
        enable = true;
        width = 2;
        active.color = "#707070";
        inactive.color = "#d0d0d0";
        urgent.color = "#cc4444";
      };

      shadow = {
        enable = true;
        softness = 30;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
        color = "#00000070";
      };
    };

    # ── Blur ────────────────────────────────────────────────
    blur = {
      noise = 0.05;
      saturation = 3;
    };


    # ── Overview ───────────────────────────────────────────
    overview.workspace-shadow.enable = false;

    # ── Hotkey overlay ─────────────────────────────────────
    hotkey-overlay.skip-at-startup = true;

    # ── Window decorations ────────────────────────────────
    prefer-no-csd = true;

    # ── Screenshots ────────────────────────────────────────
    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    # ── Animations ─────────────────────────────────────────
    animations = {
      workspace-switch = {
        enable = true;
        kind.spring = {
          damping-ratio = 0.80;
          stiffness = 523;
          epsilon = 0.0001;
        };
      };
      window-open = {
        enable = true;
        kind.easing = {
          duration-ms = 150;
          curve = "ease-out-expo";
        };
      };
      window-close = {
        enable = true;
        kind.easing = {
          duration-ms = 150;
          curve = "ease-out-quad";
        };
      };
      horizontal-view-movement = {
        enable = true;
        kind.spring = {
          damping-ratio = 0.85;
          stiffness = 423;
          epsilon = 0.0001;
        };
      };
      window-movement = {
        enable = true;
        kind.spring = {
          damping-ratio = 0.75;
          stiffness = 323;
          epsilon = 0.0001;
        };
      };
      window-resize = {
        enable = true;
        kind.spring = {
          damping-ratio = 0.85;
          stiffness = 423;
          epsilon = 0.0001;
        };
      };
      config-notification-open-close = {
        enable = true;
        kind.spring = {
          damping-ratio = 0.65;
          stiffness = 923;
          epsilon = 0.001;
        };
      };
      screenshot-ui-open = {
        enable = true;
        kind.easing = {
          duration-ms = 200;
          curve = "ease-out-quad";
        };
      };
      overview-open-close = {
        enable = true;
        kind.spring = {
          damping-ratio = 0.85;
          stiffness = 800;
          epsilon = 0.0001;
        };
      };
    };

    # ── Environment ────────────────────────────────────────
    environment = {
      XDG_CURRENT_DESKTOP = "niri";
      QT_QPA_PLATFORM = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      QT_QPA_PLATFORMTHEME = "gtk3";
      QT_QPA_PLATFORMTHEME_QT6 = "gtk3";
      NIXOS_OZONE_WL = "1";
    };

    # ── Debug ──────────────────────────────────────────────
    debug.honor-xdg-activation-with-invalid-serial = [];

    # ── Layer rules ────────────────────────────────────────
    layer-rules = [
      {
        matches = [{namespace = "^quickshell$";}];
        place-within-backdrop = true;
      }
    ];

    # ── Cursor ─────────────────────────────────────────────
    cursor = {
      theme = "Bibata_Ghost";
      size = 37;
      hide-when-typing = true;
    };
  };

  xdg.configFile.niri-config.source = lib.mkForce (
    pkgs.runCommand "niri-config-kdl" {
      inherit (cfg) finalConfig;
      passAsFile = [ "finalConfig" ];
      buildInputs = [ cfg.package ];
    } ''
      cat $finalConfigPath > $out
      printf '\ninclude optional=true "noctalia.kdl"\n' >> $out
      niri validate -c $out
    ''
  );
}
