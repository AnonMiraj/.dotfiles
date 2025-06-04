const { GLib } = imports.gi;
import App from "resource:///com/github/Aylur/ags/app.js";
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
import { MaterialIcon } from "../../.commonwidgets/materialicon.js";

const REFRESH_INTERVAL = 1000;
const SMOOTHING_SAMPLES = 5; // Number of samples for smoothing
const BYTES_TO_BITS = 8;
// BITS_TO_MBITS = 1000000; // This constant was not directly used in formatSpeed

/**
 * Format speed with appropriate units and precision
 */
const formatSpeed = (bytesPerSec) => {
    if (!bytesPerSec || isNaN(bytesPerSec) || bytesPerSec <= 0) return '0 B/s';

    const bitsPerSec = bytesPerSec * BYTES_TO_BITS;

    if (bitsPerSec < 1000) { // Less than 1 Kb/s
        return `${Math.round(bitsPerSec)} b/s`;
    } else if (bitsPerSec < 1000000) { // Less than 1 Mb/s
        return `${(bitsPerSec / 1000).toFixed(1)} Kb/s`;
    } else if (bitsPerSec < 1000000000) { // Less than 1 Gb/s
        return `${(bitsPerSec / 1000000).toFixed(1)} Mb/s`;
    } else { // Gb/s and above
        return `${(bitsPerSec / 1000000000).toFixed(2)} Gb/s`;
    }
};

/**
 * Get network interface statistics with improved error handling and SSID
 */
const getNetworkStats = () => {
    try {
        const routeOutput = Utils.exec('ip route get 1.1.1.1 2>/dev/null');
        const activeIface = routeOutput.match(/dev\s+(\S+)/)?.[1];

        if (!activeIface) {
            // console.warn('No active network interface found'); // Keep console clean for bar
            return { rxBytes: 0, txBytes: 0, interface: null, ssid: null };
        }

        const stats = Utils.exec(`cat /sys/class/net/${activeIface}/statistics/rx_bytes /sys/class/net/${activeIface}/statistics/tx_bytes 2>/dev/null`);
        const [rxBytesStr, txBytesStr] = stats.trim().split('\n');
        const rxBytes = parseInt(rxBytesStr) || 0;
        const txBytes = parseInt(txBytesStr) || 0;
        
        let ssid = null;
        // Attempt to get SSID if it's a wireless-like interface
        if (activeIface.startsWith('wlan') || activeIface.startsWith('wlp') || activeIface.startsWith('wifi')) {
            try {
                // iwgetid is a common tool for this. -r prints raw SSID.
                const ssidOutput = Utils.exec(`iwgetid -r ${activeIface} 2>/dev/null`);
                if (ssidOutput && ssidOutput.trim()) { // Check if ssidOutput is not null/empty
                    ssid = ssidOutput.trim();
                }
            } catch (e) {
                // iwgetid might not be installed, interface not wireless, or not associated
                // console.warn(`Could not get SSID for ${activeIface}. Is 'iwgetid' installed?`);
            }
        }

        return { rxBytes, txBytes, interface: activeIface, ssid };
    } catch (error) {
        // console.error('Error getting network stats:', error); // Keep console clean for bar
        return { rxBytes: 0, txBytes: 0, interface: null, ssid: null };
    }
};

/**
 * Simple moving average for speed smoothing
 */
class SpeedSmoother {
    constructor(samples = SMOOTHING_SAMPLES) {
        this.samples = samples;
        this.rxHistory = [];
        this.txHistory = [];
    }

    addSample(rxSpeed, txSpeed) {
        this.rxHistory.push(rxSpeed);
        this.txHistory.push(txSpeed);

        if (this.rxHistory.length > this.samples) {
            this.rxHistory.shift();
            this.txHistory.shift();
        }
    }

    getSmoothedSpeeds() {
        if (this.rxHistory.length === 0) return { rx: 0, tx: 0 };

        const rxAvg = this.rxHistory.reduce((sum, val) => sum + val, 0) / this.rxHistory.length;
        const txAvg = this.txHistory.reduce((sum, val) => sum + val, 0) / this.txHistory.length;

        return { rx: rxAvg, tx: txAvg };
    }

    reset() {
        this.rxHistory = [];
        this.txHistory = [];
    }
}

const NetworkSpeedIndicator = () => {
    let lastStats = { rxBytes: 0, txBytes: 0, interface: null, ssid: null };
    let lastTime = GLib.get_monotonic_time() / 1000000; // Seconds
    let updateTimeout = null;
    let initialized = false;

    const smoother = new SpeedSmoother();

    // --- UI Elements ---
    const downloadLabel = Widget.Label({
        className: 'bar-cpu-txt onSurfaceVariant', // Assuming this class provides desired text color
        label: '0 B/s',
    });

    const uploadLabel = Widget.Label({
        className: 'bar-cpu-txt onSurfaceVariant',
        label: '0 B/s',
    });

    // Apply a class that ensures icon color matches text (e.g., 'onSurfaceVariant')
    const iconColorClass = 'onSurfaceVariant'; // Use the same class as text labels for consistent color

    const downloadIcon = Widget.Box({
        className: iconColorClass, // Changed from 'sec-txt'
        child: MaterialIcon('download', 'larger'), // 'larger' or your preferred size
        tooltip_text: 'Download speed'
    });

    const uploadIcon = Widget.Box({
        className: iconColorClass, // Changed from 'sec-txt'
        child: MaterialIcon('upload', 'larger'),
        tooltip_text: 'Upload speed'
    });

    const connectionInfoLabel = Widget.Label({
        className: 'bar-cpu-txt onSurfaceVariant txt-small', // Style for combined info
        label: '',
        visible: false, // Initially hidden, toggled by click
        hpack: 'center',
        css: 'margin-left: 8px;', // Spacing from speed values
    });
    
    const downloadBox = Widget.Box({
        hexpand: true,
        spacing: 4,
        children: [downloadIcon, downloadLabel]
    });

    const uploadBox = Widget.Box({
        hexpand: true,
        spacing: 4,
        children: [uploadIcon, uploadLabel]
    });

    const mainContentBox = Widget.Box({ // This box contains speeds and connection info
        className: 'spacing-h-10', // Original class
        css: 'min-width: 15rem;',
        hpack: 'center',
        vertical: false,
        children: [
            Widget.Box({ // Box for speeds + separator
                spacing: 8,
                hpack: 'center',
                hexpand: true,
                vertical: false,
                children: [
                    downloadBox,
                    Widget.Separator({
                        // className: 'sec-txt', // Consider matching this color too if needed
                        className: iconColorClass, // Match icon/text color
                        vertical: true,
                        css: 'margin: 0 4px;' // Original margin
                    }),
                    uploadBox
                ],
            }),
            connectionInfoLabel // Add the new combined label here
        ],
    });

    const update = () => {
        try {
            const currentTime = GLib.get_monotonic_time() / 1000000; // Seconds
            const timeDelta = currentTime - lastTime;
            const currentStats = getNetworkStats();

            if (!initialized) {
                lastStats = currentStats;
                lastTime = currentTime;
                initialized = true;
                // Set initial connection info label text
                let initialInfoText = "";
                if (currentStats.ssid) {
                    initialInfoText += `SSID: ${currentStats.ssid}`;
                }
                if (currentStats.interface) {
                    initialInfoText += (initialInfoText ? ` (${currentStats.interface})` : `(${currentStats.interface})`);
                }
                connectionInfoLabel.label = initialInfoText;
                // Visibility is handled by click, but ensure it's populated if there's text
                // connectionInfoLabel.visible = initialInfoText.trim() !== "" && connectionInfoLabel.visible;


                if (!currentStats.interface) { // Handle no connection on first run too
                     downloadLabel.label = formatSpeed(0); // Show '0 B/s'
                     uploadLabel.label = formatSpeed(0);
                }
                return true;
            }

            if (timeDelta > 0.1 && currentStats.interface) { // Min 100ms delta & active interface
                const rxSpeed = Math.max(0, (currentStats.rxBytes - lastStats.rxBytes) / timeDelta);
                const txSpeed = Math.max(0, (currentStats.txBytes - lastStats.txBytes) / timeDelta);

                smoother.addSample(rxSpeed, txSpeed);
                const smoothed = smoother.getSmoothedSpeeds();

                downloadLabel.label = formatSpeed(smoothed.rx);
                uploadLabel.label = formatSpeed(smoothed.tx);

            } else if (!currentStats.interface) {
                downloadLabel.label = formatSpeed(0); // Show '0 B/s' instead of "No connection"
                uploadLabel.label = formatSpeed(0);
                smoother.reset();
            }
            
            // Update connection info label text
            let infoText = "";
            if (currentStats.ssid) {
                infoText += `SSID: ${currentStats.ssid}`;
            }
            if (currentStats.interface) {
                infoText += (infoText ? ` (${currentStats.interface})` : `(${currentStats.interface})`);
            }
            connectionInfoLabel.label = infoText;


            lastStats = currentStats;
            lastTime = currentTime;

            return true; // Continue the timeout
        } catch (error) {
            console.error('Error in network speed update:', error);
            downloadLabel.label = 'Error';
            uploadLabel.label = 'Error';
            return true;
        }
    };

    const startUpdates = () => {
        // Clear existing timeout before starting a new one
        if (updateTimeout) {
            GLib.source_remove(updateTimeout);
            updateTimeout = null;
        }
        updateTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, REFRESH_INTERVAL, update);
    };
    
    const cleanup = () => {
        if (updateTimeout) {
            GLib.source_remove(updateTimeout);
            updateTimeout = null;
        }
        // Destroy explicitly created labels and icon containers
        // The MaterialIcons are children of downloadIcon/uploadIcon Boxes, so they'll be destroyed with parent
        // downloadBox and uploadBox are children of another box, etc.
        // Destroying the top-level 'mainContentBox' should handle most, but being explicit for direct variables is safer.
        [downloadLabel, uploadLabel, downloadIcon, uploadIcon, connectionInfoLabel].forEach(widget => {
            try {
                if (widget && !widget.is_destroyed) { // Check if widget exists and not already destroyed
                    widget.destroy();
                }
            } catch (e) {
                // console.warn('Error destroying widget during cleanup:', e);
            }
        });
    };

    // Connect cleanup to the main widget's destroy signal
    mainContentBox.connect('destroy', cleanup);

    // Toggle visibility of connectionInfoLabel on click
    mainContentBox.connect('button-press-event', () => {
        if (connectionInfoLabel.label.trim() !== '') { // Only toggle if there's info to show
            connectionInfoLabel.visible = !connectionInfoLabel.visible;
        }
        return false; // Stop event propagation if needed, true to allow further handling
    });

    // Initial call to populate and start updates
    startUpdates();

    return mainContentBox;
};

export default () => NetworkSpeedIndicator();
