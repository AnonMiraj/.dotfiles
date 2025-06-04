// Presumed path: ~/.config/ags/js/widgets/networkspeed.js (or similar)

const { GLib } = imports.gi;
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
import { MaterialIcon } from "./materialicon.js";


const formatSpeed = (bytesPerSec) => {
    if (isNaN(bytesPerSec) || bytesPerSec < 0) return '0.0 Mb/s';

    const bitsPerSec = bytesPerSec * 8;
    const mbps = bitsPerSec / 1000000;
    return `${mbps.toFixed(1)} Mb/s`;
};


const getNetworkBytes = () => {
    try {
        const output = Utils.exec('ip route get 1.1.1.1');
        if (!output.includes('dev')) return { rxBytes: 0, txBytes: 0 };

        const activeIface = output.split('dev ')[1]?.split(' ')[0];
        if (!activeIface) return { rxBytes: 0, txBytes: 0 };

        const stats = Utils.exec(`ip -s link show ${activeIface}`);
        const lines = stats.split('\n');

        const rxBytesLine = lines.find(line => line.trim().startsWith('RX:') && line.includes('bytes'));
        const txBytesLine = lines.find(line => line.trim().startsWith('TX:') && line.includes('bytes'));
        
        const rxBytes = rxBytesLine ? parseInt(lines[lines.indexOf(rxBytesLine) + 1]?.trim().split(/\s+/)[0]) || 0 : 0;
        const txBytes = txBytesLine ? parseInt(lines[lines.indexOf(txBytesLine) + 1]?.trim().split(/\s+/)[0]) || 0 : 0;

        return { rxBytes, txBytes };
    } catch (error) {
        return { rxBytes: 0, txBytes: 0 };
    }
};

const NetworkSpeedIndicator = () => {
    let lastRx = 0;
    let lastTx = 0;
    let lastTime = GLib.get_monotonic_time() / 1000000;

    const downloadSpeedLabel = Widget.Label({
        className: 'bar-cpu-txt onSurfaceVariant',
        label: '0.0 Mb/s',
    });
    const uploadSpeedLabel = Widget.Label({
        className: 'bar-cpu-txt onSurfaceVariant',
        label: '0.0 Mb/s',
    });

    const downloadIconWithStyle = MaterialIcon('arrow_cool_down', 'norm', { className: 'onSurfaceVariant' });
    const uploadIconWithStyle = MaterialIcon('arrow_warm_up', 'norm', { className: 'onSurfaceVariant' });

    const speedDisplayBox = Widget.Box({
        spacing: 8,
        hpack: 'start',
        children: [
            Widget.Box({
                spacing: 4,
                children: [downloadIconWithStyle, downloadSpeedLabel],
            }),
            // Upload Speed
            Widget.Box({
                spacing: 4,
                children: [uploadIconWithStyle, uploadSpeedLabel],
            }),
        ]
    });

    const updateSpeeds = () => {
        const currentTime = GLib.get_monotonic_time() / 1000000; // seconds
        const deltaTime = currentTime - lastTime;
        const { rxBytes, txBytes } = getNetworkBytes();

        if (deltaTime > 0 && lastRx > 0 && lastTx > 0) { 
            const rxSpeed = (rxBytes - lastRx) / deltaTime;
            const txSpeed = (txBytes - lastTx) / deltaTime;
            downloadSpeedLabel.label = formatSpeed(rxSpeed);
            uploadSpeedLabel.label = formatSpeed(txSpeed);
        } else if (deltaTime > 0 && (lastRx === 0 || lastTx === 0) && (rxBytes > 0 || txBytes > 0)) {
            downloadSpeedLabel.label = formatSpeed(0);
            uploadSpeedLabel.label = formatSpeed(0);
        }


        lastRx = rxBytes;
        lastTx = txBytes;
        lastTime = currentTime;
        return true;
    };

    updateSpeeds(); 

    const timer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, updateSpeeds); // 1000ms interval

    speedDisplayBox.connect('destroy', () => {
        if (timer) {
            GLib.source_remove(timer);
        }
    });

    return speedDisplayBox;
};

export default () => NetworkSpeedIndicator();
