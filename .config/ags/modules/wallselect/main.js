import PopupWindow from '../.widgethacks/popupwindow.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import WallSelect from './wallpaper_selector.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'; // Import Utils
import GLib from 'gi://GLib'; // Import GLib
import clickCloseRegion from '../.commonwidgets/clickcloseregion.js';
import { RoundedCorner } from '../.commonwidgets/cairo_roundedcorner.js';
const { Box } = Widget;

const CYCLE_INTERVAL = 30 * 60 * 1000;

const setRandomWallpaper = async () => {
    try {
        await Utils.execAsync([`fish`, `-c`, `${App.configDir}/scripts/color_generation/wallpapers.sh -r`]);
        console.log("Wallpaper set randomly.");
    } catch (error) {
        console.error("Error setting random wallpaper automatically:", error);
    }
};

// Start the wallpaper cycling
GLib.timeout_add(GLib.PRIORITY_DEFAULT, CYCLE_INTERVAL, () => {
    setRandomWallpaper();
    return true; // Return true to keep the timer running
});


export default () => PopupWindow({
  keymode: 'on-demand',
  anchor: ['left', 'top', 'right'],
  name: 'wallselect',
  child: Box({
    vertical: true,
    children: [
      WallSelect(),
      userOptions.asyncGet().etc.widgetCorners ? Box({
        children: [
          RoundedCorner('topleft', { className: 'corner' }),
          Box({ hexpand: true }),
          RoundedCorner('topright', { className: 'corner' }),
        ]
      }) : null,
      userOptions.asyncGet().etc.clickCloseRegion ? clickCloseRegion({ name: 'wallselect', multimonitor: true, fillMonitor: 'vertical' }) : null
    ]
  })
});
