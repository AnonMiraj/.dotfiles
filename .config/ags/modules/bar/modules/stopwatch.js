// ~/.config/ags/js/custom/stopwatch.js
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import GLib from 'gi://GLib';

import { MaterialIcon } from "../../.commonwidgets/materialicon.js";

const DIR = "/dev/shm/stop-watch";
const STATUS_FILE = `${DIR}/status`;
const START_FILE = `${DIR}/start`;
const STOP_FILE = `${DIR}/stop`;

const MD_ICON_RESET = "play_circle";
const MD_ICON_RUNNING = "timer";
const MD_ICON_STOPPED = "pause"; 

const STATUS_RESET = "reset";
const STATUS_RUNNING = "running";
const STATUS_STOPPED = "stopped";

class StopwatchService extends Service {
    static {
        Service.register(
            this,
            { // Signals
                'stopwatch-changed': [],
            },
            { // Properties
                'status': ['string', 'r'],
                'time-display': ['string', 'r'],
                'icon-name': ['string', 'r'],
                'tooltip-text': ['string', 'r'],
            }
        );
    }

    _status = STATUS_RESET;
    _startTime = 0;
    _stopTime = 0;

    _timeDisplay = "";
    _iconName = MD_ICON_RESET;
    _tooltipText = "Click to start stopwatch";

    _timer = null;

    get status() { return this._status; }
    get time_display() { return this._timeDisplay; }
    get icon_name() { return this._iconName; }
    get tooltip_text() { return this._tooltipText; }

    constructor() {
        super();
        this._initFilesAndState();
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this._periodicUpdate();
            return GLib.SOURCE_CONTINUE;
        });
    }

    async _initFilesAndState() {
        try {
            await Utils.execAsync(`mkdir -p ${DIR}`);
            const initialStatus = (await Utils.readFileAsync(STATUS_FILE).catch(() => STATUS_RESET)).trim();
            this._status = [STATUS_RESET, STATUS_RUNNING, STATUS_STOPPED].includes(initialStatus) ? initialStatus : STATUS_RESET;
            if (initialStatus === "" || ![STATUS_RESET, STATUS_RUNNING, STATUS_STOPPED].includes(initialStatus)) {
                await Utils.writeFile(this._status, STATUS_FILE);
            }

            const now = Math.floor(Date.now() / 1000);
            const initialStart = (await Utils.readFileAsync(START_FILE).catch(() => String(now))).trim();
            this._startTime = parseInt(initialStart, 10) || now;
            if (initialStart === "" || isNaN(parseInt(initialStart,10))) {
                await Utils.writeFile(String(this._startTime), START_FILE);
            }

            const initialStop = (await Utils.readFileAsync(STOP_FILE).catch(() => String(now))).trim();
            this._stopTime = parseInt(initialStop, 10) || now;
            if (initialStop === "" || isNaN(parseInt(initialStop,10))) {
                await Utils.writeFile(String(this._stopTime), STOP_FILE);
            }

        } catch (error) {
            console.error("Stopwatch: Error initializing files:", error);
            const now = Math.floor(Date.now() / 1000);
            this._status = STATUS_RESET;
            this._startTime = now;
            this._stopTime = now;
        }
        this._updateDisplayProperties();
        this.notifyAllProperties();
        this.emit('stopwatch-changed');
    }

    _updateDisplayProperties() {
        const oldIconName = this._iconName;
        const oldTimeDisplay = this._timeDisplay;
        const oldTooltipText = this._tooltipText;

        let currentStopTime = this._stopTime;
        if (this._status === STATUS_RUNNING) {
            currentStopTime = Math.floor(Date.now() / 1000);
        }

        const elapsedSeconds = Math.max(0, currentStopTime - this._startTime);

        if (this._status === STATUS_RESET) {
            this._timeDisplay = "";
            this._iconName = MD_ICON_RESET;
            this._tooltipText = "Click to start stopwatch";
        } else {
            if (elapsedSeconds >= 3600) {
                const h = Math.floor(elapsedSeconds / 3600);
                const m = Math.floor((elapsedSeconds % 3600) / 60);
                const s = elapsedSeconds % 60;
                this._timeDisplay = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
            } else {
                const m = Math.floor(elapsedSeconds / 60);
                const s = elapsedSeconds % 60;
                this._timeDisplay = `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
            }

            if (this._status === STATUS_RUNNING) {
                this._iconName = MD_ICON_RUNNING;
                this._tooltipText = `Running: ${this._timeDisplay}`;
            } else { // STATUS_STOPPED
                this._iconName = MD_ICON_STOPPED;
                this._tooltipText = `Paused: ${this._timeDisplay}`;
            }
        }
        
        if (this._iconName !== oldIconName) this.notify('icon-name');
        if (this._timeDisplay !== oldTimeDisplay) this.notify('time-display');
        if (this._tooltipText !== oldTooltipText) this.notify('tooltip-text');
    }
    
    notifyAllProperties() {
        this.notify('status');
        this.notify('time-display');
        this.notify('icon-name');
        this.notify('tooltip-text');
    }

    async _periodicUpdate() {
        if (this._status === STATUS_RUNNING) {
            const prevTimeDisplay = this._timeDisplay;
            const prevTooltipText = this._tooltipText;

            this._stopTime = Math.floor(Date.now() / 1000);
            try {
                await Utils.writeFile(String(this._stopTime), STOP_FILE);
            } catch (error) {
                console.error("Stopwatch: Error writing STOP_FILE during periodic update:", error);
            }
            this._updateDisplayProperties();

            if (this._timeDisplay !== prevTimeDisplay) this.notify('time-display');
            if (this._tooltipText !== prevTooltipText) this.notify('tooltip-text');
            
            this.emit('stopwatch-changed');
        }
    }

    async _performActionAndUpdate(actionFn) {
        try {
            const fileStatus = (await Utils.readFileAsync(STATUS_FILE).catch(() => this._status)).trim();
            if ([STATUS_RESET, STATUS_RUNNING, STATUS_STOPPED].includes(fileStatus)) {
                this._status = fileStatus;
            }
        // deno-lint-ignore no-empty
        } catch {}

        await actionFn(); // Perform the core logic of toggle/reset

        try {
            await Utils.writeFile(this._status, STATUS_FILE);
            await Utils.writeFile(String(this._startTime), START_FILE);
            await Utils.writeFile(String(this._stopTime), STOP_FILE);
        } catch (error) {
            console.error("Stopwatch: Error writing files on action:", error);
        }
        
        this._updateDisplayProperties();
        this.notifyAllProperties();
        this.emit('stopwatch-changed');
    }

    async toggle() {
        await this._performActionAndUpdate(() => {
            const now = Math.floor(Date.now() / 1000);
            if (this._status === STATUS_RUNNING) {
                this._status = STATUS_STOPPED;
                this._stopTime = now;
            } else { // Was STATUS_STOPPED or STATUS_RESET
                if (this._status === STATUS_STOPPED) {
                    this._startTime = now - (this._stopTime - this._startTime);
                } else { // Was STATUS_RESET
                    this._startTime = now;
                }
                this._status = STATUS_RUNNING;
                this._stopTime = now;
            }
        });
    }

    async reset() {
        await this._performActionAndUpdate(() => {
            const now = Math.floor(Date.now() / 1000);
            this._status = STATUS_RESET;
            this._startTime = now;
            this._stopTime = now;
        });
    }

    dispose() {
        if (this._timer) {
            GLib.source_remove(this._timer);
            this._timer = null;
        }
        super.dispose();
    }
}

const stopwatchService = new StopwatchService();

const StopwatchWidget = () => {
    const iconSize = 'norm';

    const stopwatchIcon = MaterialIcon(
        stopwatchService.icon_name,
        iconSize,
        {}
    );
    stopwatchIcon.bind('label', stopwatchService, 'icon_name');

    const timeLabel = Widget.Label({
        className: 'stopwatch-time-label',
        label: stopwatchService.bind('time-display'),
    });

    return Widget.Button({
        className: 'stopwatch-ags-widget',
        on_primary_click: () => stopwatchService.toggle(),
        on_secondary_click: () => stopwatchService.reset(),
        tooltip_text: stopwatchService.bind('tooltip-text'),
        child: Widget.Box({
            className: 'txt-norm txt-onLayer1 stopwatch-content-box',
            spacing: 6,
            children: [
                stopwatchIcon,
                timeLabel,
            ],
        }),
        setup: self => self.hook(stopwatchService, () => {
            timeLabel.visible = stopwatchService.status !== STATUS_RESET;
        }, 'stopwatch-changed'),
    });
};

export default StopwatchWidget;
