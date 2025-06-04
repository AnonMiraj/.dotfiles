import App from "resource:///com/github/Aylur/ags/app.js";
import Widget from "resource:///com/github/Aylur/ags/widget.js";

import individualBrightnessServices from "../../../services/brightness.js";
import Indicator from "../../../services/indicator.js";
import GLib from "gi://GLib";
import Gio from "gi://Gio";

const BRIGHTNESS_STEP = 0.1;
const DEFAULT_WORKSPACE_LABEL = "Desktop";
const MAX_TITLE_LENGTH = 25;

const WindowTitle = async () => {
    try {
        const Hyprland = (await import(
            "resource:///com/github/Aylur/ags/service/hyprland.js"
        )).default;

        const findAppIcon = (appClass) => {
            if (!appClass) return null;

            const desktopEntry = `${appClass.toLowerCase()}.desktop`;
            const desktopPaths = [
                "/usr/share/applications/",
                "/usr/local/share/applications/",
                `${GLib.get_home_dir()}/.local/share/applications/`,
            ];

            for (const path of desktopPaths) {
                const file = Gio.File.new_for_path(`${path}${desktopEntry}`);
                if (file.query_exists(null)) {
                    const keyFile = new GLib.KeyFile();
                    keyFile.load_from_file(
                        file.get_path(),
                        GLib.KeyFileFlags.NONE,
                    );
                    const icon = keyFile.get_string(
                        "Desktop Entry",
                        "Icon",
                    );
                    if (icon) return icon;
                }
            }
            return null;
        };

        const commonLabelProps = {
            xalign: 0,
            truncate: "end",
        };

        const appIcon = Widget.Icon({
            className: "app-icon",
            size: 20,
            setup: (self) =>
                self.hook(Hyprland.active.client, () => {
                    const classname = Hyprland.active.client.class;
                    const icon = findAppIcon(classname);
                    if (!icon) {
                        self.visible = false;
                        return;
                    }
                    self.icon = icon;
                    self.visible = true;
                }),
        });

        const topLabel = Widget.Label({
            ...commonLabelProps,
            className: "txt-smaller bar-wintitle-topdesc",
            setup: (self) =>
                self.hook(Hyprland.active.client, () => {
                    self.label = Hyprland.active.client.class ||
                        DEFAULT_WORKSPACE_LABEL;
                }),
        });

        const bottomLabel = Widget.Label({
            ...commonLabelProps,
            className: "txt-smallie bar-wintitle-txt",
            setup: (self) =>
                self.hook(Hyprland.active.client, () => {
                    const title = Hyprland.active.client.title ||
                        `Workspace ${Hyprland.active.workspace.id}`;
                    self.label = title.length > MAX_TITLE_LENGTH
                        ? `${title.slice(0, MAX_TITLE_LENGTH)}...`
                        : title;
                }),
        });

        return Widget.Box({
            spacing: 3,
            children: [
                appIcon,
                Widget.Box({ className: "bar-wintitle-icon-spacer" }),
                Widget.Box({
                    vertical: true,
                    children: [topLabel, bottomLabel],
                }),
            ],
        });
    } catch (error) {
        print(`Error in WindowTitle: ${error}`);
        return null;
    }
};

export default async () => {
    const optionalWindowTitleInstance = await WindowTitle();

    const handleScroll = (direction) => {
        Indicator.popup(1);
        const step = direction * BRIGHTNESS_STEP;

        if (
            individualBrightnessServices &&
            Array.isArray(individualBrightnessServices)
        ) {
            individualBrightnessServices.forEach((serviceInstance) => {
                if (
                    serviceInstance &&
                    typeof serviceInstance.screen_value !== "undefined"
                ) {
                    serviceInstance.screen_value += step;
                }
            });
        } else {
            console.error(
                "Brightness services array is not available or not an array. Brightness not changed.",
            );
        }
    };

    return Widget.EventBox({
        onScrollUp: () => handleScroll(1),
        onScrollDown: () => handleScroll(-1),
        onPrimaryClick: () => App.toggleWindow("sideleft"),
        child: Widget.Box({
            homogeneous: false,
            children: [
                Widget.Box({ className: "bar-corner-spacing" }),
                Widget.Overlay({
                    overlays: [
                        Widget.Box({ hexpand: true }),
                        Widget.Box({
                            className: "bar-sidemodule",
                            hexpand: true,
                            children: [Widget.Box({
                                vertical: true,
                                className: "bar-space-button",
                                // Ensure null is not passed if optionalWindowTitleInstance is null
                                children: optionalWindowTitleInstance
                                    ? [optionalWindowTitleInstance]
                                    : [],
                            })],
                        }),
                    ],
                }),
            ],
        }),
    });
};
