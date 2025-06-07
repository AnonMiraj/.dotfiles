// ~/.config/ags/modules/bar/modules/pomwidget.js
//
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import App from "resource:///com/github/Aylur/ags/app.js";
import PomodoroWidget from "./pomodoro.js";

const PomodoroFloating = () =>
  Widget.Window({
    name: "pomodoro-floating",
    className: "pomodoro-floating-window",
    anchor: ["bottom", "right"],
    margins: [0, 10, 10, 0], 
    layer: "overlay",
    visible: false,
    focusable: false,
    child: Widget.Box({
      className: "pomodoro-floating-box",
      vertical: true,
      children: [
        PomodoroWidget(),
      ],
    }),
  });

export const togglePomodoroFloating = () => App.toggleWindow("pomodoro-floating");

export default PomodoroFloating;

