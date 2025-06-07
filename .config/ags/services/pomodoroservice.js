// ~/.config/ags/services/PomodoroService.js
import Service from "resource:///com/github/Aylur/ags/service.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
import GLib from "gi://GLib";

// --- File paths ---
const TIME_FILE_END = "/tmp/pomodoro_time_end";
const STATUS_FILE = "/tmp/pomodoro_status";
const TIME_FILE_INFO = "/tmp/pomodoro_time";
// ADD THIS LINE for total duration
const DURATION_FILE = "/tmp/pomodoro_duration";

// --- Icon Configuration ---
const MD_ICON_WORK = "timer";
const MD_ICON_BREAK = "eco";
const MD_ICON_STOPPED = "timer_off";

// --- Status File Content Configuration ---
const STATUS_CONTENT_BREAK = "break";
const STATUS_TEXT_WORK = "running";
const STATUS_TEXT_STOPPED = "stopped";

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
                    "double",  // progress (0.0 to 1.0)
                ],
            },
            {
                "is-running": ["boolean", "r"],
                "session-type": ["string", "r"],
                "time-display": ["string", "r"],
                "tooltip-text": ["string", "r"],
                "icon-name": ["string", "r"],
                // ADD THIS BINDABLE PROPERTY
                "progress": ["double", "r"],
            }
        );
    }

    _isRunning = false;
    _sessionType = "stopped";
    _timeDisplay = "";
    _tooltipText = "Pomodoro not running";
    _iconName = MD_ICON_STOPPED;
    _progress = 0; // Add progress property
    _timer = null;

    get is_running() { return this._isRunning; }
    get session_type() { return this._sessionType; }
    get time_display() { return this._timeDisplay; }
    get tooltip_text() { return this._tooltipText; }
    get icon_name() { return this._iconName; }
    get progress() { return this._progress; } // Add getter

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
            return false;
        }
    }

    async _updateState() {
        const wasRunning = this._isRunning;
        const previousProgress = this._progress;
        // ... (keep other 'previous' variables)
        const previousIconName = this._iconName;
        const previousTimeDisplay = this._timeDisplay;
        const previousTooltipText = this._tooltipText;
        const previousSessionType = this._sessionType;


        this._isRunning = await this._isTatsumatoRunning();
        let newTimeDisplay = "";
        let newTooltipText = "";
        let currentSessionType = "stopped";

        if (this._isRunning) {
            const statusFileContent = (await Utils.readFileAsync(STATUS_FILE).catch(() => "")).trim().toLowerCase();

            if (statusFileContent.includes(STATUS_CONTENT_BREAK)) {
                currentSessionType = "break";
                this._iconName = MD_ICON_BREAK;
            } else {
                currentSessionType = "work";
                this._iconName = MD_ICON_WORK;
            }

            const endTimeContent = await Utils.readFileAsync(TIME_FILE_END).catch(() => null);
            // --- MODIFIED SECTION ---
            const durationContent = await Utils.readFileAsync(DURATION_FILE).catch(() => null);
            const totalDuration = durationContent ? parseInt(durationContent.trim(), 10) : 0;

            if (endTimeContent) {
                const endTime = parseInt(endTimeContent.trim(), 10);
                const now = Math.floor(Date.now() / 1000);
                let remainingSeconds = endTime - now;
                if (remainingSeconds < 0) remainingSeconds = 0;

                // Calculate progress
                if (totalDuration > 0) {
                    const elapsedSeconds = totalDuration - remainingSeconds;
                    this._progress = elapsedSeconds / totalDuration;
                } else {
                    this._progress = 0;
                }

                // Format time display (no changes here)
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
                this._progress = 0; // No end time, no progress
            }
        } else { // Not running
            currentSessionType = "stopped";
            this._iconName = MD_ICON_STOPPED;
            newTimeDisplay = "";
            newTooltipText = "Pomodoro not running";
            this._progress = 0; // Reset progress

            if (wasRunning) {
                // ... (no changes to the cleanup logic)
                 Utils.writeFile(STATUS_TEXT_STOPPED, STATUS_FILE)
                     .catch(err => console.error(`AGS Pomodoro: Failed to write status file on external stop: ${err}`));
                 Utils.writeFile("Not running", TIME_FILE_INFO)
                     .catch(err => console.error(`AGS Pomodoro: Failed to write time info file on external stop: ${err}`));
            }
        }
        this._sessionType = currentSessionType;
        
        // --- MODIFIED SECTION ---
        // Check if any relevant property actually changed before notifying
        if (
            this._timeDisplay !== newTimeDisplay ||
            this._tooltipText !== newTooltipText ||
            this._isRunning !== wasRunning ||
            this._iconName !== previousIconName ||
            this._sessionType !== previousSessionType ||
            this._progress !== previousProgress // Check progress change
        ) {
            this._timeDisplay = newTimeDisplay;
            this._tooltipText = newTooltipText;

            if (this._isRunning !== wasRunning) this.notify("is-running");
            if (this._sessionType !== previousSessionType) this.notify("session-type");
            if (this._timeDisplay !== previousTimeDisplay) this.notify("time-display");
            if (this._tooltipText !== previousTooltipText) this.notify("tooltip-text");
            if (this._iconName !== previousIconName) this.notify("icon-name");
            if (this._progress !== previousProgress) this.notify("progress"); // Notify progress change

            this.emit("pomodoro-changed", this._isRunning, this._sessionType, this._timeDisplay, this._tooltipText, this._iconName, this._progress);
        }
    }

    // --- IMPORTANT ---
    // The 'toggle' function doesn't need changes, but you MUST ensure your
    // 'tatsumato' script writes the total session duration to /tmp/pomodoro_duration
    // when it starts. For example, if starting a 25-minute timer (1500s),
    // your script should execute: echo "1500" > /tmp/pomodoro_duration
    async toggle() {
        // This function remains the same. The responsibility of creating
        // the duration file is on the `tatsumato` script/command.
        const currentlyRunning = await this._isTatsumatoRunning();
        if (currentlyRunning) {
            Utils.execAsync("pkill -x tatsumato")
                .then(() => {
                    Utils.writeFile(STATUS_TEXT_STOPPED, STATUS_FILE)
                        .catch(err => console.error(`AGS Pomodoro: Failed to write status file for toggle-stop: ${err}`));
                    Utils.writeFile("Not running", TIME_FILE_INFO)
                        .catch(err => console.error(`AGS Pomodoro: Failed to write time info file: ${err}`));
                    Utils.execAsync(`rm -f ${TIME_FILE_END} ${DURATION_FILE}`) // Also remove duration file
                        .catch(err => console.warn(`AGS Pomodoro: Could not remove temp files: ${err}`));
                    this._updateState(); 
                })
                .catch(err => console.error(`AGS Pomodoro: Failed to kill tatsumato: ${err}`));
        } else {
            // NOTE: Your tatsumato command MUST write the duration to DURATION_FILE
            // e.g., tatsumato -a -p -d && echo "1500" > /tmp/pomodoro_duration
            Utils.execAsync(["fish", "-c", "tatsumato -a -p -d && echo 1500 > /tmp/pomodoro_duration &"])
                .then(() => {
                    Utils.writeFile(STATUS_TEXT_WORK, STATUS_FILE)
                        .catch(err => console.error(`AGS Pomodoro: Failed to write status file for toggle-start: ${err}`));
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
export default pomodoroService;
