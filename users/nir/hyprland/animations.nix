# Animation curves + leaves.
#
# niri springs are converted to Hyprland spring curves. niri's `damping-ratio`
# is the damping ratio zeta, and Hyprland wants the damping coefficient:
#   dampening = zeta * 2 * sqrt(stiffness * mass)
# NOTE: Hyprland 0.56 spells the field `dampening` (see the shipped
# example/hyprland.lua at tag v0.56.2), not `damping`.
# niri `easing` curves become cubic beziers. Expect a tuning pass on real
# hardware; the numbers below are the mechanical translation, not a taste pass.
{...}: {
  wayland.windowManager.hyprland.settings = {
    # `settings.curve` entries are rendered before animations because "curve"
    # is in the module's importantPrefixes list.
    curve = [
      # niri workspace-switch: stiffness 523, ratio 0.80
      {
        _args = [
          "niriWorkspace"
          {
            type = "spring";
            mass = 1.0;
            stiffness = 523.0;
            dampening = 36.6;
          }
        ];
      }
      # niri horizontal-view-movement: stiffness 423, ratio 0.85
      {
        _args = [
          "niriView"
          {
            type = "spring";
            mass = 1.0;
            stiffness = 423.0;
            dampening = 35.0;
          }
        ];
      }
      # niri window-movement: stiffness 323, ratio 0.75
      {
        _args = [
          "niriWindowMove"
          {
            type = "spring";
            mass = 1.0;
            stiffness = 323.0;
            dampening = 27.0;
          }
        ];
      }
      # niri window-resize: stiffness 423, ratio 0.85
      {
        _args = [
          "niriResize"
          {
            type = "spring";
            mass = 1.0;
            stiffness = 423.0;
            dampening = 35.0;
          }
        ];
      }
      # niri window-open easing: 150ms ease-out-expo
      {
        _args = [
          "niriOpen"
          {
            type = "bezier";
            points = [
              [0.16 1.0]
              [0.3 1.0]
            ];
          }
        ];
      }
      # niri window-close easing: 150ms ease-out-quad
      {
        _args = [
          "niriClose"
          {
            type = "bezier";
            points = [
              [0.25 0.46]
              [0.45 0.94]
            ];
          }
        ];
      }
    ];

    animation = [
      # niri window-open (150ms)
      {
        leaf = "windowsIn";
        enabled = true;
        speed = 1.5;
        bezier = "niriOpen";
        style = "popin 90%";
      }
      # niri window-close (150ms)
      {
        leaf = "windowsOut";
        enabled = true;
        speed = 1.5;
        bezier = "niriClose";
        style = "popin 90%";
      }
      # niri window-movement
      {
        leaf = "windowsMove";
        enabled = true;
        speed = 2.5;
        spring = "niriWindowMove";
      }
      # niri stacks workspaces vertically, so the switch animation has to be
      # the vertical variant: `slide` slides horizontally (the wrong axis),
      # `slidevert` slides vertically like niri.
      {
        leaf = "workspaces";
        enabled = true;
        speed = 3.0;
        spring = "niriWorkspace";
        style = "slidevert";
      }
      {
        leaf = "border";
        enabled = true;
        speed = 3.0;
        spring = "niriResize";
      }
      {
        leaf = "fade";
        enabled = true;
        speed = 2.0;
        bezier = "niriOpen";
      }
    ];
  };
}
