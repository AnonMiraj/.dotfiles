import Audio from "resource:///com/github/Aylur/ags/service/audio.js";
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import { MaterialIcon } from "../../.commonwidgets/materialicon.js";
// import { languages } from "../../.commonwidgets/statusicons_languages.js";
const { GLib } = imports.gi;

export const MicIndicator = () =>
    Widget.Button({
        onClicked: () => {
            if (Audio.microphone)
                Audio.microphone.isMuted = !Audio.microphone.isMuted;
        },
        onScrollUp: () => {
            if (Audio.microphone) Audio.microphone.volume += 0.05;
        },
        onScrollDown: () => {
            if (Audio.microphone) Audio.microphone.volume -= 0.05;
        },
        child: Widget.Box({
            children: [
                Widget.Stack({
                    transition: "slide_up_down",
                    transitionDuration: userOptions.asyncGet().animations.durationSmall,
                    children: {
                        true: MaterialIcon("mic_off", "norm"),
                        false: MaterialIcon("mic", "norm"),
                    },
                    setup: (self) =>
                        self.hook(Audio, (stack) => {
                            if (!Audio.microphone) return;
                            stack.shown = String(Audio.microphone.isMuted);
                        }),
                }),
            ],
        }),
        setup: (self) =>
            self.hook(Audio, () => {
                if (!Audio.microphone) {
                    self.tooltip_text = "Input not available";
                    return;
                }
                const vol = Math.round(Audio.microphone.volume * 100);
                const desc = Audio.microphone.description?.length > 30
                    ? Audio.microphone.description.substring(0, 27) + "..."
                    : Audio.microphone.description;
                self.tooltip_text = `${desc} • ${vol}%`;
            }),
    });

export const SpeakerIndicator = () =>
    Widget.Button({
        onClicked: () => {
            if (Audio.speaker) Audio.speaker.isMuted = !Audio.speaker.isMuted;
        },
        onScrollUp: () => {
            if (Audio.speaker) Audio.speaker.volume += 0.05;
        },
        onScrollDown: () => {
            if (Audio.speaker) Audio.speaker.volume -= 0.05;
        },
        child: Widget.Box({
            children: [
                Widget.Stack({
                    transition: "slide_up_down",
                    transitionDuration: userOptions.asyncGet().animations.durationSmall,
                    children: {
                        true: MaterialIcon("volume_off", "norm"),
                        false: MaterialIcon("volume_up", "norm"),
                    },
                    setup: (self) =>
                        self.hook(Audio, (stack) => {
                            if (!Audio.speaker) return;
                            stack.shown = String(Audio.speaker.isMuted);
                        }),
                }),
            ],
        }),
        setup: (self) =>
            self.hook(Audio, () => {
                if (!Audio.speaker) {
                    self.tooltip_text = "Output not available";
                    return;
                }
                const vol = Math.round(Audio.speaker.volume * 100);
                const desc = Audio.speaker.description?.length > 30
                    ? Audio.speaker.description.substring(0, 27) + "..."
                    : Audio.speaker.description;
                self.tooltip_text = `${desc} • ${vol}%`;
            }),
    });

const BarToggles = (props = {}, monitor = 0) =>
    Widget.Box({
        ...props,
        child: Widget.Box({
            className: "bar-button",
            children: [
                Widget.Box({
                    className: "spacing-h-10 sec-txt ",
                    children: [
                        MicIndicator(),
                        SpeakerIndicator(),
                    ],
                }),
            ],
        }),
    });
export default () => BarToggles();
