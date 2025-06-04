// ~/.config/ags/js/custom/pomodoro.js
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import Service from "resource:///com/github/Aylur/ags/service.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
import GLib from "gi://GLib";

// IMPORTANT: Verify this path is correct relative to where you save pomodoro.js
import { MaterialIcon } from "../../.commonwidgets/materialicon.js";

// File paths
const TIME_FILE_END = "/tmp/pomodoro_time_end";
const STATUS_FILE = "/tmp/pomodoro_status";
const TIME_FILE_INFO = "/tmp/pomodoro_time";

// --- Icon Configuration ---
const MD_ICON_WORK = "timer";
const MD_ICON_BREAK = "eco";
const MD_ICON_STOPPED = "timer_off";

// --- Status File Content Configuration ---
// For reading from STATUS_FILE
const STATUS_CONTENT_BREAK = "break"; // If STATUS_FILE contains this, it's a break

// For writing to STATUS_FILE by this AGS widget
const STATUS_TEXT_WORK = "running";    // Written when this widget starts tatsumato
const STATUS_TEXT_STOPPED = "stopped"; // Written when this widget stops tatsumato, or detects external stop

class PomodoroService extends Service {
    static {
        Service.register(
            this,
            {
                "pomodoro-changed": [
                    "boolean", // isRunning
                    "string",  // sessionType
                    "string",  // timeDisplay
                    "string",  // tooltipText
                    "string",  // iconName
                ],
            },
            {
                "is-running": ["boolean", "r"],
                "session-type": ["string", "r"], // "work", "break", "stopped"
                "time-display": ["string", "r"],
                "tooltip-text": ["string", "r"],
                "icon-name": ["string", "r"],
            }
        );
    }

    _isRunning = false;
    _sessionType = "stopped";
    _timeDisplay = "";
    _tooltipText = "Pomodoro not running";
    _iconName = MD_ICON_STOPPED;
    _timer = null;

    get is_running() { return this._isRunning; }
    get session_type() { return this._sessionType; }
    get time_display() { return this._timeDisplay; }
    get tooltip_text() { return this._tooltipText; }
    get icon_name() { return this._iconName; }

    constructor() {
        super();
        this._updateState();
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this._updateState();
            return GLib.SOURCE_CONTINUE;
        });
    }

    async _isTatsumatoRunning() {
        try {
            const output = await Utils.execAsync("pgrep -x tatsumato");
            return output.trim() !== "";
        } catch (e) {
            // pgrep returns 1 (error) if no process found, or if pgrep itself fails.
            // Treat any error as tatsumato not running.
            // console.warn("AGS Pomodoro: pgrep check for tatsumato failed or process not found.");
            return false;
        }
    }

    async _updateState() {
        const wasRunning = this._isRunning;
        const previousIconName = this._iconName;
        const previousTimeDisplay = this._timeDisplay;
        const previousTooltipText = this._tooltipText;
        const previousSessionType = this._sessionType;

        this._isRunning = await this._isTatsumatoRunning(); // This should now be reliable
        let newTimeDisplay = "";
        let newTooltipText = "";
        let currentSessionType = "stopped"; // Default unless tatsumato is running

        if (this._isRunning) {
            const statusFileContent = (await Utils.readFileAsync(STATUS_FILE).catch(() => "")).trim().toLowerCase();

            if (statusFileContent.includes(STATUS_CONTENT_BREAK)) {
                currentSessionType = "break";
                this._iconName = MD_ICON_BREAK;
            } else { // Default to "work" if running and not explicitly "break" (e.g., statusFileContent is "running" or empty)
                currentSessionType = "work";
                this._iconName = MD_ICON_WORK;
            }

            const endTimeContent = await Utils.readFileAsync(TIME_FILE_END).catch(() => null);
            if (endTimeContent) {
                const endTime = parseInt(endTimeContent.trim(), 10);
                const now = Math.floor(Date.now() / 1000);
                let remainingSeconds = endTime - now;
                if (remainingSeconds < 0) remainingSeconds = 0;

                if (remainingSeconds >= 3600) {
                    const h = Math.floor(remainingSeconds / 3600);
                    const m = Math.floor((remainingSeconds % 3600) / 60);
                    const s = remainingSeconds % 60;
                    newTimeDisplay = `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
                } else {
                    const m = Math.floor(remainingSeconds / 60);
                    const s = remainingSeconds % 60;
                    newTimeDisplay = `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
                }
                newTooltipText = `${currentSessionType === "work" ? "Work session" : "Break time"}: ${newTimeDisplay} remaining`;
            } else {
                newTimeDisplay = "??:??";
                newTooltipText = `${currentSessionType === "work" ? "Work session" : "Break time"} active (no end time file)`;
            }
        } else { // Not running
            currentSessionType = "stopped";
            this._iconName = MD_ICON_STOPPED; // Correctly set the stopped icon
            newTimeDisplay = "";
            newTooltipText = "Pomodoro not running";

            // If tatsumato was previously running and now detected as stopped (e.g., killed externally)
            // update the status files to reflect this.
            if (wasRunning) {
                Utils.writeFile(STATUS_TEXT_STOPPED, STATUS_FILE)
                    .catch(err => console.error(`AGS Pomodoro: Failed to write status file on external stop: ${err}`));
                Utils.writeFile("Not running", TIME_FILE_INFO)
                    .catch(err => console.error(`AGS Pomodoro: Failed to write time info file on external stop: ${err}`));
            }
        }
        this._sessionType = currentSessionType;

        // Check if any relevant property actually changed before notifying and emitting
        if (
            this._timeDisplay !== newTimeDisplay ||
            this._tooltipText !== newTooltipText ||
            this._isRunning !== wasRunning ||
            this._iconName !== previousIconName ||
            this._sessionType !== previousSessionType
        ) {
            this._timeDisplay = newTimeDisplay;
            this._tooltipText = newTooltipText;

            if (this._isRunning !== wasRunning) this.notify("is-running");
            if (this._sessionType !== previousSessionType) this.notify("session-type");
            if (this._timeDisplay !== previousTimeDisplay) this.notify("time-display");
            if (this._tooltipText !== previousTooltipText) this.notify("tooltip-text");
            if (this._iconName !== previousIconName) this.notify("icon-name");

            this.emit("pomodoro-changed", this._isRunning, this._sessionType, this._timeDisplay, this._tooltipText, this._iconName);
        }
    }

    async toggle() {
        const currentlyRunning = await this._isTatsumatoRunning(); // Check fresh status
        if (currentlyRunning) {
            Utils.execAsync("pkill -x tatsumato")
                .then(() => {
                    Utils.writeFile(STATUS_TEXT_STOPPED, STATUS_FILE) // Write "stopped"
                        .catch(err => console.error(`AGS Pomodoro: Failed to write status file for toggle-stop: ${err}`));
                    Utils.writeFile("Not running", TIME_FILE_INFO)
                        .catch(err => console.error(`AGS Pomodoro: Failed to write time info file: ${err}`));
                    Utils.execAsync(`rm -f ${TIME_FILE_END}`)
                        .catch(err => console.warn(`AGS Pomodoro: Could not remove ${TIME_FILE_END}: ${err}`));
                    // No need to call _updateState() here, the service's timer will call it next second
                    // or force an immediate update if desired:
                    this._updateState(); 
                })
                .catch(err => console.error(`AGS Pomodoro: Failed to kill tatsumato: ${err}`));
        } else {
            Utils.execAsync(["fish", "-c", "tatsumato -a -p -d &>/dev/null &"]) // Ensure shell is correct or use 'bash'
                .then(() => {
                    Utils.writeFile(STATUS_TEXT_WORK, STATUS_FILE) // Write "running"
                        .catch(err => console.error(`AGS Pomodoro: Failed to write status file for toggle-start: ${err}`));
                    // Force an immediate update after starting
                     this._updateState();
                })
                .catch(err => console.error(`AGS Pomodoro: Failed to start tatsumato: ${err}`));
        }
    }

    dispose() {
        if (this._timer) {
            GLib.source_remove(this._timer);
            this._timer = null;
        }
        super.dispose();
    }
}

const pomodoroService = new PomodoroService();

// --- PomodoroWidget --- (No changes needed in the widget structure itself)
const PomodoroWidget = () => {
    const iconSize = "norm";

    const pomodoroIcon = MaterialIcon(
        pomodoroService.icon_name,
        iconSize,
        {},
    );
    pomodoroIcon.bind("label", pomodoroService, "icon_name");

    const timeLabel = Widget.Label({
        label: pomodoroService.bind("time-display"),
    });

    return Widget.Button({
        on_clicked: () => pomodoroService.toggle(),
        tooltip_text: pomodoroService.bind("tooltip-text"),
        child: Widget.Box({
            className: "txt-norm txt-onLayer1",
            spacing: 6,
            children: [
                pomodoroIcon,
                timeLabel,
            ],
        }),
        setup: (self) =>
            self.hook(pomodoroService, () => {
                timeLabel.visible = pomodoroService.is_running &&
                    pomodoroService.time_display !== "";
            }, "pomodoro-changed"),
    });
};

export default PomodoroWidget;
