import Widget from "resource:///com/github/Aylur/ags/widget.js";
import WindowTitle from "../normal/spaceleft.js";
import Music from "../normal/mixed.js";
import Clock from "../modules/maclock.js";
import PomodoroStatus from "../modules/pomodoro.js";
import StopwatchWidget from "../modules/stopwatch.js";

import { SideModule } from "./../../.commonwidgets/sidemodule.js";
import NormalOptionalWorkspaces from "../normal/workspaces_hyprland.js";
import ScrolledModule from "../../.commonwidgets/scrolledmodule.js";
import NetworkSpeed from "../../.commonwidgets/networkspeed.js";
import PrayerTimesWidget from "../modules/prayertimes.js";
import micWidget from "../modules/bar_toggles.js";
import Weather from "../modules/weatherOnly.js";

import { Tray } from "../modules/tray.js";
import battery from "../modules/battery.js";
const opts = userOptions.asyncGet();
const workspaces = opts.bar.elements.showWorkspaces;
const Box = Widget.Box;

export const NormalBar = Widget.CenterBox({
  className: "bar-bg shadow-window",
  css: `padding:0.2rem 1rem`,
  startWidget: Widget.Box({
    className: "spacing-h-4",
    children: [
      ...(userOptions.asyncGet().bar.elements.showWindowTitle
        ? [await WindowTitle()]
        : []),

      Box({
        hexpand: false,
        hpack: "start",
        className: "bar-group bar-group-standalone",
        css: `padding : 0; min-width:20px`,
        children: [
          micWidget(),
          NetworkSpeed(),
        ],
      }),
    ],
  }),
  centerWidget: Widget.Box({
    // spacing: 3,
    children: [
      SideModule([Music()]),

      Widget.Box({
        hexpand: true,
        className: "bar-group bar-group-standalone",
        css: `padding:0 12px;margin: 4px 5px`,
        children: [...(workspaces ? [NormalOptionalWorkspaces()] : [])],
      }),

      Widget.Box({
        child: Clock(),
        className: "bar-group bar-group-standalone",
        css: `padding:0 12px;margin: 4px 5px`,
        vpack: "center",
      }),
      ScrolledModule({
        children: [
          Widget.Box({
            child: PomodoroStatus(),
            className: "bar-group bar-group-standalone",
            css: `padding:0 12px;margin: 4px 5px`,
            vpack: "center",
          }),

          Widget.Box({
            child: StopwatchWidget(),
            className: "bar-group bar-group-standalone",
            css: `padding:0 12px;margin: 4px 5px`,
            vpack: "center",
          }),
        ],
      }),
    ],
  }),
  endWidget: Widget.Box({
    children: [
      Widget.Box({
        hexpand: true,
        hpack: "end",
        className: "bar-group bar-group-standalone",
        children: [
          Box({
            children: [
              Tray(),
            ],
          }),
          ScrolledModule({
            children: [
              Widget.Box({
                hpack: "end",
                hexpand: true,
                children: [
                  PrayerTimesWidget(),
                ],
              }),
              Widget.Box({
                hpack: "end",
                hexpand: true,

                children: [
                  Weather(),
                ],
              }),
            ],
          }),
          battery(),
        ],
      }),
    ],
  }),
});
