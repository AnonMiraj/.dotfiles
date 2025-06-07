// ~/.config/ags/modules/bar/modules/pomodoro.js
import Widget from "resource:///com/github/Aylur/ags/widget.js";

// IMPORTANT: Adjust these paths based on your actual file structure
import { MaterialIcon } from "../../.commonwidgets/materialicon.js";
import pomodoroService from "../../../services/pomodoroservice.js";

// --- PomodoroWidget --- 
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
        setup: (self) => {
            self.set_size_request(60, -1);
        },
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
