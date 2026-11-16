// Grow only the requested edge; ignore other windows and respect panels.
function expandToEdge(direction) {
    const window = workspace.activeWindow;
    if (!window || window.specialWindow || window.fullScreen || !window.resizeable) {
        return;
    }

    const area = workspace.clientArea(KWin.MaximizeArea, window);
    const frame = window.frameGeometry;
    const geometry = { x: frame.x, y: frame.y, width: frame.width, height: frame.height };

    switch (direction) {
    case "Left": {
        const left = Math.min(geometry.x, area.x);
        geometry.width += geometry.x - left;
        geometry.x = left;
        break;
    }
    case "Right":
        geometry.width = Math.max(geometry.width, area.x + area.width - geometry.x);
        break;
    case "Up": {
        const top = Math.min(geometry.y, area.y);
        geometry.height += geometry.y - top;
        geometry.y = top;
        break;
    }
    case "Down":
        geometry.height = Math.max(geometry.height, area.y + area.height - geometry.y);
        break;
    default:
        return;
    }

    // Already at (or beyond) the edge: don't disturb tiling/maximization.
    if (geometry.x === frame.x && geometry.y === frame.y &&
        geometry.width === frame.width && geometry.height === frame.height) {
        return;
    }

    // Leave a custom tile before resizing, without resizing the tile itself.
    window.tile = null;
    window.setMaximize(false, false);
    window.frameGeometry = geometry;
}

["Left", "Right", "Up", "Down"].forEach(function (direction) {
    registerShortcut(
        "Expand Window to " + direction + " Edge",
        "Expand Window to " + direction + " Edge",
        "Meta+Alt+" + direction,
        function () { expandToEdge(direction); }
    );
});
