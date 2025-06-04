import Widget from "resource:///com/github/Aylur/ags/widget.js";
import { barPosition, currentShellMode } from "../../variables.js";
import { RoundedCorner } from "../.commonwidgets/cairo_roundedcorner.js";
import { enableClickthrough } from "../.widgetutils/clickthrough.js";
import { NormalBar } from "./modes/normal.js";
import { FocusBar } from "./modes/focus.js";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";

// Get the saved mode from gsettings
const SCHEMA_ID = "org.gnome.shell.extensions.ags";
const KEY_BAR_MODE = "bar-mode";
const settings = new Gio.Settings({ schema_id: SCHEMA_ID });
const DEFAULT_MODE = settings.get_string(KEY_BAR_MODE) || "0";

// Performance optimization: Cache bar components
const barComponentCache = new Map();

const modes = new Map([
  ["0", [await NormalBar, true, "Normal"]],
  ["1", [await FocusBar, true, "Focus"]],
]);

const shouldShowCorners = (monitor) => {
  const mode = currentShellMode.value[monitor] || DEFAULT_MODE;
  const shouldShow = modes.get(mode)?.[1] ?? false;
  return shouldShow;
};

const getValidPosition = (currentPos) => {
  return (currentPos === "top" || currentPos === "bottom") ? currentPos : "top";
};

/**
 * Cache for corner windows to avoid recreating them
 */
const cornerCache = new Map();

/**
 * Creates a corner for the bar with performance optimizations
 * @param {number} monitor - Monitor ID
 * @param {string} side - Side of the corner ("left" or "right")
 * @returns {Widget.Window} - Corner window
 */
const createCorner = (monitor, side) => {
  // Check if we already have a cached corner
  const cacheKey = `corner-${monitor}-${side}`;
  if (cornerCache.has(cacheKey)) {
    return cornerCache.get(cacheKey);
  }

  // Helper function to determine corner style (assuming horizontal bar)
  const getCornerStyle = (pos) => {
    // pos is "top" or "bottom"
    // side is "left" or "right"
    return pos === "top"
      ? (side === "left" ? "topleft" : "topright")
      : (side === "left" ? "bottomleft" : "bottomright");
  };

  // Create the corner window with optimized hooks
  const cornerWindow = Widget.Window({
    monitor,
    name: `barcorner${side[0]}${monitor}`,
    layer: "top",
    anchor: [
      getValidPosition(
        barPosition.value,
      ),
      side, // Anchor side is directly 'left' or 'right'
    ],
    exclusivity: "normal",
    visible: shouldShowCorners(monitor),
    child: RoundedCorner(
      getCornerStyle(
        getValidPosition(
          barPosition.value,
        ),
      ),
      { className: "corner" },
    ),
    setup: (self) => {
      enableClickthrough(self);

      // Use a debounced update function for better performance
      let updateTimeout = 0;

      // Store the last state to avoid redundant updates
      let lastMode = currentShellMode.value[monitor] || DEFAULT_MODE;
      let lastPosition = barPosition.value;
      let lastVisibility = shouldShowCorners(monitor);
      let lastCornerStyle = getCornerStyle(
        getValidPosition(lastPosition),
      );
      let lastAnchorString = JSON.stringify([
        getValidPosition(lastPosition),
        side,
      ]);

      const updateCorner = () => {
        // Cancel any pending update
        if (updateTimeout) {
          GLib.source_remove(updateTimeout);
          updateTimeout = 0;
        }

        // Schedule a new update with debouncing (longer timeout)
        updateTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
          const mode = currentShellMode.value[monitor] || DEFAULT_MODE;
          const pos = getValidPosition(barPosition.value);
          // isVert variable and related logic removed
          const shouldShow = shouldShowCorners(monitor);

          // Check if anything has actually changed
          const hasStateChanged = mode !== lastMode ||
            pos !== getValidPosition(lastPosition) ||
            shouldShow !== lastVisibility;

          if (hasStateChanged) {
            // Only update if visibility changed
            if (self.visible !== shouldShow) {
              self.visible = shouldShow;
              lastVisibility = shouldShow;

              // Only update child and anchor if visible
              if (shouldShow) {
                const newCornerStyle = getCornerStyle(pos);
                self.child = RoundedCorner(newCornerStyle, {
                  className: "corner",
                });
                lastCornerStyle = newCornerStyle;

                const newAnchor = [pos, side];
                self.anchor = newAnchor;
                lastAnchorString = JSON.stringify(newAnchor);

                self.show_all();
              }
            } else if (shouldShow) {
              // If visibility didn't change but we're visible, check if we need to update the corner style or anchor
              const newCornerStyle = getCornerStyle(pos);
              const newAnchor = [pos, side];
              const newAnchorString = JSON.stringify(newAnchor);

              // Only update if necessary
              if (
                (self.child && lastCornerStyle !== newCornerStyle) ||
                lastAnchorString !== newAnchorString
              ) {
                self.child = RoundedCorner(newCornerStyle, {
                  className: "corner",
                });
                self.anchor = newAnchor;

                // Update cached values
                lastCornerStyle = newCornerStyle;
                lastAnchorString = newAnchorString;

                self.show_all();
              }
            }

            // Update cached mode and position
            lastMode = mode;
            lastPosition = barPosition.value;
          }

          updateTimeout = 0;
          return GLib.SOURCE_REMOVE;
        });
      };

      // Use a single hook for both variables to reduce redundant updates
      const hookId1 = self.hook(currentShellMode, updateCorner);
      const hookId2 = self.hook(barPosition, updateCorner);

      // Properly handle destruction to prevent GC issues
      self.connect("destroy", () => {
        if (updateTimeout) {
          GLib.source_remove(updateTimeout);
          updateTimeout = 0;
        }

        // Unhook to prevent memory leaks
        if (hookId1) self.unhook(hookId1);
        if (hookId2) self.unhook(hookId2);

        // Properly destroy child widget
        if (self.child && typeof self.child.destroy === "function") {
          self.child.destroy();
        }

        // Clear child reference to help GC
        self.child = null;

        // Remove from cache
        cornerCache.delete(cacheKey);
      });
    },
  });

  // Cache the corner window
  cornerCache.set(cacheKey, cornerWindow);

  return cornerWindow;
};

const getAnchor = () => {
  const currentPos = barPosition.value;
  const position = getValidPosition(currentPos); // position will be "top" or "bottom"

  if (position !== currentPos) {
    barPosition.value = position;
  }

  // Anchor for a horizontal bar: [edge, start_fill, end_fill]
  return [position, "left", "right"];
};

export const BarCornerTopleft = (monitor = 0) => createCorner(monitor, "left");
export const BarCornerTopright = (monitor = 0) =>
  createCorner(monitor, "right");

import userOptions from "../.configuration/user_options.js";

// Cache user options to avoid repeated calls to asyncGet()
let cachedOptions = null;
const getOptions = () => {
  if (!cachedOptions) {
    cachedOptions = userOptions.asyncGet();

    // Set up a timer to refresh the cache periodically (every 30 seconds)
    const intervalId = Utils.interval(30000, () => {
      cachedOptions = userOptions.asyncGet();
      return true; // Continue the interval
    });

    // Register the interval for cleanup
    if (
      globalThis.cleanupRegistry &&
      typeof globalThis.cleanupRegistry.registerInterval === "function"
    ) {
      globalThis.cleanupRegistry.registerInterval(intervalId);
    }
  }
  return cachedOptions;
};

/**
 * Creates a bar for the specified monitor
 * Performance optimized version that:
 * 1. Caches components to avoid recreating them
 * 2. Reduces logging to improve performance
 * 3. Uses more efficient reactivity patterns
 * 4. Properly handles widget destruction to prevent GC issues
 */
export const Bar = async (monitor = 0) => {
  // Check if we already have a cached bar for this monitor
  const cacheKey = `bar-${monitor}`;
  if (barComponentCache.has(cacheKey)) {
    // Only log in multi-monitor setups
    if (Hyprland.monitors.length > 1) {
      console.log(`Using cached bar for monitor ${monitor}`);
    }
    return barComponentCache.get(cacheKey);
  }

  const opts = getOptions();
  const mode = currentShellMode.value[monitor] || DEFAULT_MODE;

  // Create corners only once and cache them
  const corners = ["left", "right"].map((side) => createCorner(monitor, side));

  // Create stack children only once
  const children = {};
  for (const [key, [component]] of modes) {
    try {
      children[key] = component;
    } catch (error) {
      // Only log in multi-monitor setups
      if (Hyprland.monitors.length > 1) {
        console.log(`Error creating component for mode ${key}: ${error}`);
      }
    }
  }

  // Create the stack with optimized hooks
  const stack = Widget.Stack({
    homogeneous: false,
    transition: "slide_up_down",
    transitionDuration: opts.animations.durationSmall,
    children: children,
    setup: (self) => {
      // Use a single hook with a debounced update
      let updateTimeout = 0;

      // Store the last mode to avoid redundant updates
      let lastMode = currentShellMode.value[monitor] || DEFAULT_MODE;

      const updateStack = () => {
        if (updateTimeout) {
          GLib.source_remove(updateTimeout);
          updateTimeout = 0;
        }

        // Use a longer debounce time to reduce frequency of updates
        updateTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
          const newMode = currentShellMode.value[monitor] || DEFAULT_MODE;

          // Only update if the mode has actually changed
          if (self.shown !== newMode && lastMode !== newMode) {
            self.shown = newMode;
            lastMode = newMode;

            // Only log in multi-monitor setups
            if (Hyprland.monitors.length > 1) {
              console.log(
                `Bar stack for monitor ${monitor} updated to mode ${newMode}`,
              );
            }
          }

          updateTimeout = 0;
          return GLib.SOURCE_REMOVE;
        });
      };

      // Connect to the hook
      const hookId = self.hook(currentShellMode, updateStack);
      self.shown = mode;

      // Properly handle destruction to prevent GC issues
      self.connect("destroy", () => {
        if (updateTimeout) {
          GLib.source_remove(updateTimeout);
          updateTimeout = 0;
        }

        // Unhook to prevent memory leaks
        if (hookId) {
          self.unhook(hookId);
        }

        // Properly clean up all children
        if (self.children) {
          // Explicitly destroy each child widget
          Object.values(self.children).forEach((child) => {
            if (child && typeof child.destroy === "function") {
              child.destroy();
            }
          });
          self.children = {};
        }
      });
    },
  });

  // Create the bar window with optimized hooks
  const bar = Widget.Window({
    monitor,
    name: `bar${monitor}`,
    anchor: getAnchor(),
    exclusivity: "exclusive",
    visible: true,
    child: stack,
    setup: (self) => {
      // Use a single hook with a debounced update for both currentShellMode and barPosition
      let updateTimeout = 0;

      // Store the last mode and anchor to avoid redundant updates
      let lastMode = currentShellMode.value[monitor] || DEFAULT_MODE;
      let lastPosition = barPosition.value;
      let lastAnchorString = JSON.stringify(getAnchor());

      const updateAnchor = () => {
        // Cancel any pending update
        if (updateTimeout) {
          GLib.source_remove(updateTimeout);
          updateTimeout = 0;
        }

        // Use a longer debounce time to reduce frequency of updates
        updateTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
          const newMode = currentShellMode.value[monitor] || DEFAULT_MODE;
          const newPosition = barPosition.value;

          // Only proceed if mode or position has actually changed
          if (newMode !== lastMode || newPosition !== lastPosition) {
            const newAnchor = getAnchor();
            const newAnchorString = JSON.stringify(newAnchor);

            // Only update if the anchor has actually changed
            if (newAnchorString !== lastAnchorString) {
              self.anchor = newAnchor;

              // Only log in multi-monitor setups
              if (Hyprland.monitors.length > 1) {
                console.log(
                  `Bar window for monitor ${monitor} anchor updated for mode ${newMode}`,
                );
              }

              // Update the stored values
              lastMode = newMode;
              lastPosition = newPosition;
              lastAnchorString = newAnchorString;
            }
          }

          updateTimeout = 0;
          return GLib.SOURCE_REMOVE;
        });
      };

      // Use a single hook for both variables and store the hook IDs
      const hookId1 = self.hook(currentShellMode, updateAnchor);
      const hookId2 = self.hook(barPosition, updateAnchor);

      // Properly handle destruction to prevent GC issues
      self.connect("destroy", () => {
        if (updateTimeout) {
          GLib.source_remove(updateTimeout);
          updateTimeout = 0;
        }

        // Unhook to prevent memory leaks
        if (hookId1) self.unhook(hookId1);
        if (hookId2) self.unhook(hookId2);

        // Properly destroy child widget
        if (self.child && typeof self.child.destroy === "function") {
          self.child.destroy();
        }

        // Clear child reference to help GC
        self.child = null;

        // Remove from cache
        barComponentCache.delete(cacheKey);
      });
    },
  });

  // Cache the result
  const result = [bar, ...corners];
  barComponentCache.set(cacheKey, result);

  return result;
};
