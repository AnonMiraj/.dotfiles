import Widget from "resource:///com/github/Aylur/ags/widget.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
import App from "resource:///com/github/Aylur/ags/app.js";
import GLib from "gi://GLib";
import Gio from "gi://Gio";
import Gtk from "gi://Gtk";
import GdkPixbuf from "gi://GdkPixbuf";
import Gdk from "gi://Gdk";
// Assuming Cairo is available for FontSlant/FontWeight. If not, AGS might provide alternatives or it might work implicitly.
// import Cairo from 'gi://cairo';
import userOptions from "../.configuration/user_options.js";
import { MaterialIcon } from "../.commonwidgets/materialicon.js";

const { Box, Label, EventBox, Scrollable, Button } = Widget;

let opts, etc;
let elevate,
    WALLPAPER_DIR,
    PREVIEW_WIDTH,
    PREVIEW_HEIGHT,
    PREVIEW_CORNER,
    HIGH_QUALITY_PREVIEW,
    DISK_CACHE_DIR;

const IMAGES_PER_PAGE = 30;
const NUM_PAGES_TO_RENDER_AROUND_CURRENT = 1;
let logicalCurrentPage = 0;
let contentUpdateCallback = null; // Callback to refresh the main content
let wallpaperPathsCache = null; // Cache for the list of wallpaper file paths
let wallpaperPathsCacheTime = 0; // Timestamp for the wallpaperPathsCache
const FILE_LIST_CACHE_DURATION = 60 * 1000; // 1 minute in milliseconds

let showOnlyGifs = false; // State variable for GIF filter

async function initializeConfiguration() {
    try {
        const config = await userOptions.asyncGet();
        opts = config.wallselect;
        etc = config.etc;

        elevate = etc.widgetCorners
            ? "wall-rounding shadow-window"
            : "elevation shadow-window";
        WALLPAPER_DIR = GLib.get_home_dir() +
            (opts.wallpaperFolder || "/Pictures/Wallpapers");
        PREVIEW_WIDTH = opts.width || 200;
        PREVIEW_HEIGHT = opts.height || 120;
        PREVIEW_CORNER = opts.radius || 18;
        HIGH_QUALITY_PREVIEW = opts.highQualityPreview;
        DISK_CACHE_DIR = GLib.get_user_cache_dir() + "/ags/user/wallpapers";

        GLib.mkdir_with_parents(WALLPAPER_DIR, 0o755);
        GLib.mkdir_with_parents(DISK_CACHE_DIR, 0o755);
    } catch (error) {
        console.error(
            "Failed to initialize wallpaper selector configuration:",
            error,
        );
        opts = {
            wallpaperFolder: "/Pictures/Wallpapers",
            width: 200,
            height: 120,
            radius: 18,
            highQualityPreview: false,
            spacing: 10,
        };
        etc = { widgetCorners: true };
        elevate = etc.widgetCorners
            ? "wall-rounding shadow-window"
            : "elevation shadow-window";
        WALLPAPER_DIR = GLib.get_home_dir() + opts.wallpaperFolder;
        PREVIEW_WIDTH = opts.width;
        PREVIEW_HEIGHT = opts.height;
        PREVIEW_CORNER = opts.radius;
        HIGH_QUALITY_PREVIEW = opts.highQualityPreview;
        DISK_CACHE_DIR = GLib.get_user_cache_dir() + "/ags/user/wallpapers";
        GLib.mkdir_with_parents(WALLPAPER_DIR, 0o755);
        GLib.mkdir_with_parents(DISK_CACHE_DIR, 0o755);
    }
}

const getCacheInfo = (path) => {
    const basename = GLib.path_get_basename(path);
    const dotIndex = basename.lastIndexOf(".");
    const ext = dotIndex !== -1
        ? basename.substring(dotIndex + 1).toLowerCase()
        : "png";
    return { cachedFileName: basename, format: ext === "jpg" ? "jpeg" : ext };
};

const loadPreviewAsync = async (path) => {
    if (!path || typeof path !== "string") {
        console.error("loadPreviewAsync: Invalid path provided.");
        throw new Error("Invalid path for wallpaper preview.");
    }
    const { cachedFileName, format } = getCacheInfo(path);
    const diskCachePath = DISK_CACHE_DIR + "/" + cachedFileName;
    const diskCacheFile = Gio.File.new_for_path(diskCachePath);
    const originalFile = Gio.File.new_for_path(path);

    if (diskCacheFile.query_exists(null)) {
        try {
            if (!originalFile.query_exists(null)) {
                console.warn(
                    `loadPreviewAsync: Original file "${path}" for cache "${diskCachePath}" no longer exists. Deleting stale cache.`,
                );
                diskCacheFile.delete(null);
            } else {
                const diskInfo = diskCacheFile.query_info(
                    "time::modified",
                    Gio.FileQueryInfoFlags.NONE,
                    null,
                );
                const originalInfo = originalFile.query_info(
                    "time::modified",
                    Gio.FileQueryInfoFlags.NONE,
                    null,
                );
                if (
                    originalInfo.get_attribute_uint64("time::modified") <=
                        diskInfo.get_attribute_uint64("time::modified")
                ) {
                    try {
                        return GdkPixbuf.Pixbuf.new_from_file(diskCachePath);
                    } catch (e) {
                        console.warn(
                            `loadPreviewAsync: Cache file "${diskCachePath}" for "${path}" seems corrupt (${e}), deleting and regenerating.`,
                        );
                        try {
                            diskCacheFile.delete(null);
                        } catch (deleteError) {
                            console.error(
                                `loadPreviewAsync: Failed to delete corrupt cache file "${diskCachePath}": ${deleteError}`,
                            );
                        }
                    }
                }
            }
        } catch (e) {
            console.warn(
                `loadPreviewAsync: Error in cache check for "${path}": ${e}. Attempting regeneration.`,
            );
        }
    }
    if (!originalFile.query_exists(null)) {
        const errorMessage =
            `loadPreviewAsync: Original file "${path}" not found. Cannot generate preview.`;
        console.error(errorMessage);
        throw new Error(errorMessage);
    }
    let pixbuf;
    try {
        if (path.toLowerCase().endsWith(".gif")) {
            const animation = GdkPixbuf.PixbufAnimation.new_from_file(path);
            pixbuf = animation.get_static_image().scale_simple(
                PREVIEW_WIDTH,
                PREVIEW_HEIGHT,
                GdkPixbuf.InterpType.BILINEAR,
            );
        } else if (HIGH_QUALITY_PREVIEW) {
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                path,
                PREVIEW_WIDTH,
                PREVIEW_HEIGHT,
                true,
            );
        } else {
            const fullPixbuf = GdkPixbuf.Pixbuf.new_from_file(path);
            pixbuf = fullPixbuf.scale_simple(
                PREVIEW_WIDTH,
                PREVIEW_HEIGHT,
                GdkPixbuf.InterpType.NEAREST,
            );
        }
        if (!pixbuf) throw new Error("Pixbuf creation resulted in null.");
    } catch (generationError) {
        console.error(
            `loadPreviewAsync: Failed to generate pixbuf for "${path}": ${generationError}`,
        );
        throw generationError;
    }
    try {
        pixbuf.savev(diskCachePath, format, [], []);
    } catch (e) {
        console.error(
            `loadPreviewAsync: Error saving disk cached image "${diskCachePath}": ${e}`,
        );
    }
    return pixbuf;
};

const getWallpaperPaths = async () => {
    try {
        const now_us = GLib.get_monotonic_time();
        if (
            wallpaperPathsCache &&
            (now_us - wallpaperPathsCacheTime <
                (FILE_LIST_CACHE_DURATION * 1000))
        ) {
            return wallpaperPathsCache;
        }
        // console.log(`getWallpaperPaths: Scanning WALLPAPER_DIR "${WALLPAPER_DIR}" for paths...`);
        const dir = Gio.File.new_for_path(WALLPAPER_DIR);
        if (!dir.query_exists(null)) {
            console.warn(
                `getWallpaperPaths: Wallpaper directory "${WALLPAPER_DIR}" not found. Returning empty list.`,
            );
            wallpaperPathsCache = [];
            wallpaperPathsCacheTime = now_us;
            return [];
        }
        const wallpaperFiles = [];
        const validExtensions = new Set([
            ".jpg",
            ".jpeg",
            ".png",
            ".gif",
            ".webp",
            ".tga",
            ".tiff",
            ".bmp",
            ".ico",
        ]);
        const enumerateDirectory = (currentDir) => {
            try {
                const enumerator = currentDir.enumerate_children(
                    "standard::name,standard::type",
                    Gio.FileQueryInfoFlags.NONE,
                    null,
                );
                let fileInfo;
                while ((fileInfo = enumerator.next_file(null)) !== null) {
                    const fileName = fileInfo.get_name();
                    if (fileName.startsWith(".")) continue;
                    const childFile = currentDir.get_child(fileName);
                    if (fileInfo.get_file_type() === Gio.FileType.DIRECTORY) {
                        enumerateDirectory(childFile);
                    } else {
                        const dotIndex = fileName.lastIndexOf(".");
                        if (dotIndex !== -1) {
                            const fileExtension = fileName.substring(dotIndex)
                                .toLowerCase();
                            if (validExtensions.has(fileExtension)) {
                                wallpaperFiles.push(childFile.get_path());
                            }
                        }
                    }
                }
            } catch (error) {
                console.error(
                    `getWallpaperPaths: Error enumerating directory "${currentDir.get_path()}": ${error}`,
                );
            }
        };
        enumerateDirectory(dir);
        wallpaperPathsCache = wallpaperFiles.sort();
        wallpaperPathsCacheTime = now_us;
        // console.log(`getWallpaperPaths: Updated cache with ${wallpaperPathsCache.length} paths.`);
        return wallpaperPathsCache;
    } catch (error) {
        console.error(
            "getWallpaperPaths: CRITICAL Error while searching for images:",
            error,
        );
        wallpaperPathsCache = [];
        wallpaperPathsCacheTime = GLib.get_monotonic_time();
        return [];
    }
};

const WallpaperPreview = (path) => {
    let hasAttemptedLoad = false;
    let loadError = null;
    return Button({
        className: "wallpaper-preview-btn",
        child: EventBox({
            setup: (self) => {
                const drawingArea = new Gtk.DrawingArea();
                drawingArea.set_size_request(PREVIEW_WIDTH, PREVIEW_HEIGHT);
                self.add(drawingArea);
                let pixbuf = null;
                let imageLoaded = false;
                let loadPromise = null;
                const loadImage = () => {
                    if (imageLoaded || loadPromise) return;
                    hasAttemptedLoad = true;
                    loadError = null;
                    loadPromise = Utils.timeout(50, () => {
                        loadPreviewAsync(path)
                            .then((p) => {
                                pixbuf = p;
                                imageLoaded = true;
                                drawingArea.queue_draw();
                            })
                            .catch((e) => {
                                console.error(
                                    `WallpaperPreview: Preview loading failed for "${path}": ${e.message}`,
                                );
                                loadError = e.message || "Unknown error";
                                imageLoaded = false;
                                pixbuf = null;
                                drawingArea.queue_draw();
                            })
                            .finally(() => {
                                loadPromise = null;
                            });
                        return false;
                    });
                };
                if (self.get_realized() && self.get_mapped()) loadImage();
                else self.connect("map", loadImage);
                drawingArea.connect("draw", (widget, cr) => {
                    const areaWidth = widget.get_allocated_width();
                    const areaHeight = widget.get_allocated_height();
                    cr.save();
                    cr.newPath();
                    cr.arc(
                        PREVIEW_CORNER,
                        PREVIEW_CORNER,
                        PREVIEW_CORNER,
                        Math.PI,
                        1.5 * Math.PI,
                    );
                    cr.arc(
                        areaWidth - PREVIEW_CORNER,
                        PREVIEW_CORNER,
                        PREVIEW_CORNER,
                        1.5 * Math.PI,
                        2 * Math.PI,
                    );
                    cr.arc(
                        areaWidth - PREVIEW_CORNER,
                        areaHeight - PREVIEW_CORNER,
                        PREVIEW_CORNER,
                        0,
                        0.5 * Math.PI,
                    );
                    cr.arc(
                        PREVIEW_CORNER,
                        areaHeight - PREVIEW_CORNER,
                        PREVIEW_CORNER,
                        0.5 * Math.PI,
                        Math.PI,
                    );
                    cr.closePath();
                    cr.clip();
                    if (pixbuf) {
                        const pixbufWidth = pixbuf.get_width();
                        const pixbufHeight = pixbuf.get_height();
                        const pixbufAspect = pixbufWidth / pixbufHeight;
                        const areaAspect = areaWidth / areaHeight;
                        let drawWidth, drawHeight, x, y;
                        if (pixbufAspect > areaAspect) {
                            drawHeight = areaHeight;
                            drawWidth = drawHeight * pixbufAspect;
                            x = (areaWidth - drawWidth) / 2;
                            y = 0;
                        } else {
                            drawWidth = areaWidth;
                            drawHeight = drawWidth / pixbufAspect;
                            x = 0;
                            y = (areaHeight - drawHeight) / 2;
                        }
                        drawWidth = Math.max(1, Math.round(drawWidth));
                        drawHeight = Math.max(1, Math.round(drawHeight));
                        const scaledPixbuf = pixbuf.scale_simple(
                            drawWidth,
                            drawHeight,
                            GdkPixbuf.InterpType.BILINEAR,
                        );
                        if (scaledPixbuf) {
                            Gdk.cairo_set_source_pixbuf(
                                cr,
                                scaledPixbuf,
                                Math.round(x),
                                Math.round(y),
                            );
                            cr.paint();
                        } else {
                            console.error(
                                `WallpaperPreview: Failed to scale pixbuf for ${path}`,
                            );
                            loadError = "Scale fail";
                        }
                    }
                    if (!pixbuf && hasAttemptedLoad && !loadPromise) {
                        cr.set_source_rgb(0.3, 0.1, 0.1);
                        cr.rectangle(0, 0, areaWidth, areaHeight);
                        cr.fill();
                        cr.set_source_rgb(0.9, 0.9, 0.9);
                        cr.select_font_face(
                            "sans-serif",
                            Gdk.Cairo?.FontSlant.NORMAL || 0,
                            Gdk.Cairo?.FontWeight.NORMAL || 400,
                        ); // Fallback if Cairo not directly available
                        cr.set_font_size(12);
                        const text = `Error: ${
                            loadError ? loadError.substring(0, 20) : "Load"
                        }`;
                        const extents = cr.text_extents(text);
                        cr.move_to(
                            Math.max(5, (areaWidth - extents.width) / 2),
                            areaHeight / 2 + extents.height / 2,
                        );
                        cr.show_text(text);
                    } else if (!imageLoaded && !loadError) {
                        cr.set_source_rgb(0.15, 0.15, 0.2);
                        cr.rectangle(0, 0, areaWidth, areaHeight);
                        cr.fill();
                        cr.set_source_rgb(0.7, 0.7, 0.7);
                        cr.select_font_face(
                            "sans-serif",
                            Gdk.Cairo?.FontSlant.ITALIC || 1,
                            Gdk.Cairo?.FontWeight.NORMAL || 400,
                        );
                        cr.set_font_size(12);
                        const loadText = "Loading...";
                        const extentsLoad = cr.text_extents(loadText);
                        cr.move_to(
                            Math.max(5, (areaWidth - extentsLoad.width) / 2),
                            areaHeight / 2 + extentsLoad.height / 2,
                        );
                        cr.show_text(loadText);
                    }
                    cr.restore();
                    return false;
                });
            },
        }),
        onClicked: async () => {
            try {
                await Utils.execAsync([
                    `fish`,
                    `-c`,
                    `${App.configDir}/scripts/color_generation/wallpapers.sh -S "${path}"`,
                ]);
                App.closeWindow("wallselect");
            } catch (error) {
                console.error(
                    `WallpaperPreview: Error during script execution for "${path}":`,
                    error,
                );
            }
        },
    });
};

const createPlaceholder = (isFiltered = false) => {
    const message = showOnlyGifs && isFiltered
        ? "No GIFs found."
        : "No wallpapers found in your folder.";
    const subMessage = showOnlyGifs && isFiltered
        ? "Try showing all or adding GIF files to:"
        : "Please add images to:";
    return Box({
        className: "wallpaper-placeholder",
        vertical: true,
        vexpand: true,
        hexpand: true,
        vpack: "center",
        hpack: "center",
        spacing: 10,
        children: [
            MaterialIcon("image_search", "extraLarge", {
                className: "onSurfaceVariant",
            }),
            Label({ label: message, className: "txt-norm onSurfaceVariant" }),
            Label({
                label: subMessage,
                opacity: 0.8,
                className: "txt-small onSurfaceVariant",
            }),
            Label({
                label: `${WALLPAPER_DIR}`,
                wrap: true,
                justify: Gtk.Justification.CENTER,
                opacity: 0.7,
                className: "txt-small onSurfaceVariant",
            }),
        ],
    });
};

const createPaginationControls = (totalPages) => {
    const pageInfoLabel = Label({
        className: "wallpaper-pagination-counter txt-norm onSurfaceVariant",
        xalign: 0.5,
        label: totalPages > 0
            ? `${Math.min(logicalCurrentPage + 1, totalPages)}/${totalPages}`
            : "0/0",
        css: "min-width: 40px; margin: 0 2px;", // Added some horizontal margin
    });

    // Helper to update all button sensitivities and page display
    // This will be called by contentUpdateCallback implicitly by reconstructing,
    // but direct call can be used by scroll events on gif button for responsiveness before full reconstruct.
    // However, simpler to just rely on contentUpdateCallback.

    const updateGifFilterButtonContent = (button) => {
        if (!button || !button.child) return;
        button.child.children[0].icon = showOnlyGifs ? "image" : "gif_box";
        button.tooltipText = showOnlyGifs
            ? "Show All Images"
            : "Show Only GIFs (Scroll on button to change page)";
        button.toggleClassName("active-filter", showOnlyGifs);
    };

    const gifFilterButton = Button({
        className: "wallpaper-filter-btn wallpaper-pagination-btn", // Added pagination class
        onClicked: () => {
            showOnlyGifs = !showOnlyGifs;
            logicalCurrentPage = 0; // Reset to first page when filter changes
            // updateGifFilterButtonContent(gifFilterButton); // Button will be recreated by contentUpdateCallback
            if (contentUpdateCallback) contentUpdateCallback();
        },
        child: Box({
            spacing: 5,
            hpack: "center",
            children: [
                MaterialIcon(showOnlyGifs ? "image" : "gif_box", "small"), // Smaller icon
            ],
        }),
        setup: (self) => Utils.idle(() => updateGifFilterButtonContent(self)),
    });

    const navButtons = [];
    const createNavButton = (iconName, tooltip, action, sensitivityCheck) => {
        const button = Button({
            className: "wallpaper-pagination-btn",
            child: MaterialIcon(iconName, "norm", {
                className: "onSurfaceVariant",
            }),
            tooltipText: tooltip,
            sensitive: sensitivityCheck ? sensitivityCheck() : (totalPages > 0),
            onClicked: () => {
                action();
                // Sensitivity and page label will be updated by contentUpdateCallback via createContent
                if (contentUpdateCallback) contentUpdateCallback();
            },
        });
        navButtons.push(button); // Keep track for potential direct updates if needed
        return button;
    };

    const children = [
        createNavButton("shuffle", "Set a random wallpaper", async () => {
            try {
                await Utils.execAsync([
                    `fish`,
                    `-c`,
                    `${App.configDir}/scripts/color_generation/wallpapers.sh ${
                        showOnlyGifs ? "-g" : "-r"
                    }`,
                ]);
                App.closeWindow("wallselect");
            } catch (error) {
                console.error("Error setting random wallpaper:", error);
            }
        }, () => totalPages > 0),
        createNavButton("first_page", "First page", () => {
            logicalCurrentPage = 0;
        }, () => logicalCurrentPage > 0 && totalPages > 0),
        createNavButton("navigate_before", "Previous page", () => {
            if (logicalCurrentPage > 0) logicalCurrentPage--;
        }, () => logicalCurrentPage > 0 && totalPages > 0),
        pageInfoLabel,
        createNavButton("navigate_next", "Next page", () => {
            if (logicalCurrentPage < totalPages - 1) logicalCurrentPage++;
        }, () => logicalCurrentPage < totalPages - 1 && totalPages > 0),
        createNavButton("last_page", "Last page", () => {
            logicalCurrentPage = totalPages - 1;
        }, () => logicalCurrentPage < totalPages - 1 && totalPages > 0),
        gifFilterButton,
    ];

    return Box({
        className: "material-pagination-container",
        hpack: "center",
        spacing: 2, // Reduced spacing for a tighter look
        children: children,
    });
};

const createContent = async () => {
    try {
        const allWallpaperPaths = await getWallpaperPaths();
        let effectiveWallpaperPaths = allWallpaperPaths;
        if (showOnlyGifs) {
            effectiveWallpaperPaths = allWallpaperPaths.filter(path => path.toLowerCase().endsWith(".gif"));
        }

        const totalLogicalPages = effectiveWallpaperPaths.length > 0
            ? Math.ceil(effectiveWallpaperPaths.length / IMAGES_PER_PAGE)
            : 0;

        // Ensure logicalCurrentPage is within valid bounds
        if (logicalCurrentPage >= totalLogicalPages && totalLogicalPages > 0) {
            logicalCurrentPage = totalLogicalPages - 1;
        }
        if (logicalCurrentPage < 0) {
            logicalCurrentPage = 0;
        }

        // Determine the actual range of logical pages to render
        let startPageToRender = 0;
        let endPageToRender = -1; // Means no pages to render initially

        if (totalLogicalPages > 0) {
            startPageToRender = Math.max(0, logicalCurrentPage - NUM_PAGES_TO_RENDER_AROUND_CURRENT);
            endPageToRender = Math.min(totalLogicalPages - 1, logicalCurrentPage + NUM_PAGES_TO_RENDER_AROUND_CURRENT);

            // Adjust window to ensure we try to render the desired number of pages if available
            const desiredNumPagesInView = (2 * NUM_PAGES_TO_RENDER_AROUND_CURRENT) + 1;
            let currentNumPagesInView = endPageToRender - startPageToRender + 1;

            if (currentNumPagesInView < desiredNumPagesInView) {
                if (startPageToRender === 0 && endPageToRender < totalLogicalPages -1) { // At the beginning, try to extend to the right
                    endPageToRender = Math.min(totalLogicalPages - 1, startPageToRender + desiredNumPagesInView - 1);
                } else if (endPageToRender === totalLogicalPages - 1 && startPageToRender > 0) { // At the end, try to extend to the left
                    startPageToRender = Math.max(0, endPageToRender - desiredNumPagesInView + 1);
                }
            }
        }
        
        const itemsForGrid = (totalLogicalPages > 0)
            ? effectiveWallpaperPaths.slice(
                startPageToRender * IMAGES_PER_PAGE,
                (endPageToRender + 1) * IMAGES_PER_PAGE
            )
            : [];

        if (itemsForGrid.length === 0) {
            const isDueToFilter = showOnlyGifs && allWallpaperPaths.length > 0;
            const placeholderBox = createPlaceholder(isDueToFilter);
            // Pass totalLogicalPages to pagination controls even when placeholder is shown
            const paginationControls = createPaginationControls(totalLogicalPages);
            return Box({
                vertical: true, vexpand: true, hexpand: true,
                spacing: 10,
                children: [
                    Box({ child: placeholderBox, vexpand: true, hexpand: true }),
                    paginationControls
                ]
            });
        }

        const wallpaperGrid = Box({
            className: "wallpaper-list", hexpand: true, hpack: "center",
            spacing: opts.spacing || 10,
            children: itemsForGrid.map(path => WallpaperPreview(path)),
        });

        const scrollableContent = Scrollable({
            hexpand: true, vexpand: true, hscroll: "automatic", vscroll: "never",
            child: wallpaperGrid,
            css: `min-height: ${PREVIEW_HEIGHT + 20}px; padding: 5px 0;`,
        });

        const scrollHandlerEventBox = EventBox({
            vexpand: true,
            onScrollUp: () => {
                const adj = scrollableContent.get_hadjustment();
                if (!adj) return;
                const currentValue = adj.get_value();
                const lowerBound = adj.get_lower();
                const scrollAmount = PREVIEW_WIDTH / 1.5;

                if (currentValue <= lowerBound) {
                    // At the beginning of the currently rendered block.
                    // Can we go to a "previous" block? Yes, if startPageToRender > 0
                    if (startPageToRender > 0) {
                        logicalCurrentPage = Math.max(0, logicalCurrentPage - 1); // Or more aggressively: logicalCurrentPage = startPageToRender - 1;
                        if (contentUpdateCallback) contentUpdateCallback();
                        return;
                    }
                }
                adj.set_value(Math.max(currentValue - scrollAmount, lowerBound));
            },
            onScrollDown: () => {
                const adj = scrollableContent.get_hadjustment();
                if (!adj) return;
                const currentValue = adj.get_value();
                const upperBound = adj.get_upper();
                const pageSize = adj.get_page_size();
                const scrollAmount = PREVIEW_WIDTH / 1.5;

                if (currentValue >= (upperBound - pageSize - 0.1)) {
                    // At the end of the currently rendered block.
                    // Can we go to a "next" block? Yes, if endPageToRender < totalLogicalPages - 1
                    if (endPageToRender < totalLogicalPages - 1) {
                        logicalCurrentPage = Math.min(totalLogicalPages - 1, logicalCurrentPage + 1); // Or more aggressively: logicalCurrentPage = endPageToRender + 1;
                        if (contentUpdateCallback) contentUpdateCallback();
                        return;
                    }
                }
                adj.set_value(Math.min(currentValue + scrollAmount, upperBound - pageSize));
            },
            child: scrollableContent,
        });

        return Box({
            vertical: true, spacing: 10, vexpand: true,
            children: [
                scrollHandlerEventBox,
                createPaginationControls(totalLogicalPages), // Pass total LOGICAL pages
            ],
        });
    } catch (error) {
        console.error("Wallpapers: CRITICAL Error in createContent:", error);
        return Box({
            className: "wallpaper-error", vexpand: true, hexpand: true, vpack: "center", hpack: "center",
            children: [Label({ label: `Error creating content: ${error.message}`, className: "txt-large txt-error", wrap: true })],
        });
    }
};export default () => {
    return Box({
        vertical: true,
        className: `wallselect-bg ${elevate}`,
        css: `min-width: ${
            Math.max(PREVIEW_WIDTH * 2 + 100, 450)
        }px; min-height: ${
            Math.max(PREVIEW_HEIGHT * 2 + 100, 350)
        }px; padding: 10px;`,
        children: [
            Box({
                className: "wallselect-header",
                css: "margin-bottom: 10px;",
                children: [
                    Label({
                        label: "Select Wallpaper",
                        hexpand: true,
                        xalign: 0.5,
                        className: "txt-title-large onSurface",
                    }),
                ],
            }),
            Box({ // Main Content Area
                vertical: true,
                vpack: "fill",
                hexpand: true,
                vexpand: true,
                className: "wallselect-content",
                setup: (self) => {
                    const loadInitialContent = async () => {
                        try {
                            await initializeConfiguration();
                            logicalCurrentPage = 0;
                            showOnlyGifs = false;
                            wallpaperPathsCache = null;
                            self.children = [await createContent()];
                        } catch (error) {
                            console.error(
                                "Wallpapers: Error on initial content creation:",
                                error,
                            );
                            self.children = [
                                Label({
                                    label:
                                        `Failed to load wallpapers: ${error.message}`,
                                    wrap: true,
                                    className: "txt-error",
                                }),
                            ];
                        }
                    };
                    contentUpdateCallback = async () => {
                        try {
                            self.children = [await createContent()];
                        } catch (error) {
                            console.error(
                                "Wallpapers: Error in contentUpdateCallback:",
                                error,
                            );
                            self.children = [
                                Label({
                                    label:
                                        `Failed to update content: ${error.message}`,
                                    wrap: true,
                                    className: "txt-error",
                                }),
                            ];
                        }
                    };
                    Utils.idle(loadInitialContent);
                    self.hook(App, async (_, windowName, visible) => {
                        if (windowName === "wallselect" && visible) {
                            // console.log("Wallpapers: Window 'wallselect' toggled visible. Reloading.");
                            await loadInitialContent();
                        }
                    }, "window-toggled");
                },
            }),
        ],
    });
};
