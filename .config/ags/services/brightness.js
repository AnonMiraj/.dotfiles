import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js";
import Service from "resource:///com/github/Aylur/ags/service.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
const { exec } = Utils;

import { clamp } from "../modules/.miscutils/mathfuncs.js";

class BrightnessServiceBase extends Service {
    static {
        Service.register(
            this,
            { "screen-changed": ["float"] },
            { "screen-value": ["float", "rw"] },
        );
    }

    _screenValue = 0;

    // the getter has to be in snake_case
    get screen_value() {
        return this._screenValue;
    }

    // the setter has to be in snake_case too
    set screen_value(percent) {
        percent = clamp(percent, 0, 1);
        this._screenValue = percent;

        Utils.execAsync(this.setBrightnessCmd(percent))
            .then(() => {
                // signals has to be explicity emitted
                this.emit("screen-changed", percent);
                this.notify("screen-value");

                // or use Service.changed(propName: string) which does the above two
                // this.changed('screen');
            })
            .catch(print);
    }

    // overwriting connectWidget method, lets you
    // change the default event that widgets connect to
    connectWidget(widget, callback, event = "screen-changed") {
        super.connectWidget(widget, callback, event);
    }
}

class BrightnessCtlService extends BrightnessServiceBase {
    static {
        Service.register(this);
    }

    constructor() {
        super();
        const current = Number(exec("brightnessctl g"));
        const max = Number(exec("brightnessctl m"));
        this._screenValue = current / max;
    }

    setBrightnessCmd(percent) {
        return `brightnessctl s ${percent * 100}% -q`;
    }
}

class BrightnessDdcService extends BrightnessServiceBase {
    static {
        Service.register(this);
    }

    constructor(busNum) {
        super();
        this._busNum = busNum;
        Utils.execAsync(`ddcutil -b ${this._busNum} getvcp 10 --brief`)
            .then((out) => {
                // only the last line is useful
                out = out.split("\n");
                out = out[out.length - 1];

                out = out.split(" ");
                const current = Number(out[3]);
                const max = Number(out[4]);
                this._screenValue = current / max;
            })
            .catch(print);
    }

    setBrightnessCmd(percent) {
        return `ddcutil -b ${this._busNum} setvcp 10 ${
            Math.round(percent * 100)
        }`;
    }
}

async function listDdcMonitorsSnBus() {
    const ddcSnBus = {};

    // Its' better not to use --brief. This way if a serial number is not
    // found we can still use the binary serial number as an alternative
    const out = await Utils.execAsync("ddcutil detect");
    const displays = out.split("\n\n");
    displays.forEach((display) => {
        const reg = /[Dd]isplay/;
        if (!reg.test(display)) {
            return;
        }
        const lines = display.split("\n");
        let sn, busNum;
        let unresponsive = false;
        for (let line of lines) {
            line = line.trim();

            // Sometimes ddcutils will report a DP monitor twice, one of the
            // two copies of the monitor will "not support DDC/CI". Just ignore it
            // See https://www.ddcutil.com/faq/#duplicate_displayport
            if (line.includes("unresponsive")) {
                unresponsive = true;
            }
            if (line.startsWith("Serial")) {
                sn = line.split(":")[1].trim();
                // Sometimes sn can be empty. In this cases let's relay on binary sn
            } else if (line.startsWith("Binary") && !sn) {
                // Make the serial number upper case except for the leading '0x' since Hyprland
                // seems to use upper case for the rest of the string and ddcutil uses
                // lower case for all the binary sn
                sn = "0x" + line.split("(")[1].slice(2, -1).toUpperCase();
            } else if (line.startsWith("I2C bus:")) {
                busNum = line.split("/dev/i2c-")[1];
            }
        }
        if (sn && busNum && !unresponsive) {
            ddcSnBus[sn] = busNum;
        }
    });
    return ddcSnBus;
}

// Service instance
const numMonitors = Hyprland.monitors.length;
const service = Array(numMonitors);
const ddcSnBus = await listDdcMonitorsSnBus();
for (let i = 0; i < service.length; i++) {
    const monitorName = Hyprland.monitors[i].name;
    const monitorSn = Hyprland.monitors[i].serial;
    const preferredController =
        userOptions.asyncGet().brightness.controllers[monitorName] ||
        userOptions.asyncGet().brightness.controllers.default || "auto";
    if (preferredController) {
        switch (preferredController) {
            case "brightnessctl":
                service[i] = new BrightnessCtlService();
                break;
            case "ddcutil":
                service[i] = new BrightnessDdcService(ddcSnBus[monitorSn]);
                break;
            case "auto":
                if (
                    monitorSn in ddcSnBus &&
                    !!exec(`bash -c 'command -v ddcutil'`)
                ) {
                    service[i] = new BrightnessDdcService(ddcSnBus[monitorSn]);
                } else {
                    service[i] = new BrightnessCtlService();
                }
                break;
            default:
                throw new Error(
                    `Unknown brightness controller ${preferredController}`,
                );
        }
    }
}

// make it global for easy use with cli
globalThis.brightness = service[0];

// export to use in other modules
export default service;
