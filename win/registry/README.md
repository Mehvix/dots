# registry


```pwsh
reg import explorer/show-file-extensions.on.reg     # or double-click
reg import explorer/show-file-extensions.off.reg    # revert to Windows default
```

- `admin` files touch HKLM: run from an elevated shell.
- `explorer restart`: `taskkill /f /im explorer.exe; start explorer`.
- `.off.reg` restores the Windows default (explicit value, or deletes the value/key).
- Header of each file: description, when it takes effect, `admin` if needed.

| tweak | effect | applies |
|---|---|---|
| `explorer/show-file-extensions` | Show file extensions | explorer restart |
| `explorer/show-hidden-files` | Show hidden files | explorer restart |
| `explorer/full-path-titlebar` | Show full path in Explorer title bar | explorer restart |
| `explorer/open-to-this-pc` | Explorer opens to This PC instead of Home | explorer restart |
| `explorer/no-recent-frequent` | Hide recent files / frequent folders in Home | explorer restart |
| `explorer/nav-pane-expand` | Navigation pane expands to current folder | explorer restart |
| `explorer/compact-mode` | Compact Explorer view (less padding) | explorer restart |
| `explorer/classic-context-menu` | Classic right-click menu (no 'Show more options') | explorer restart |
| `explorer/no-shortcut-suffix` | New shortcuts are not named '... - Shortcut' | explorer restart |
| `taskbar/align-left` | Left-align taskbar icons / Start | immediate |
| `taskbar/hide-task-view` | Hide Task View button | immediate |
| `taskbar/hide-widgets` | Hide Widgets button (24H2+ UCPD may deny the write; use Settings then) | immediate |
| `taskbar/hide-search` | Hide taskbar search box/icon | explorer restart |
| `taskbar/never-combine` | Never combine taskbar buttons (show labels), all monitors | explorer restart |
| `taskbar/clock-seconds` | Show seconds in taskbar clock | explorer restart |
| `taskbar/end-task` | 'End task' in taskbar right-click menu | immediate |
| `taskbar/start-no-recommendations` | Start: no Recommended / recent docs, more pins | explorer restart |
| `taskbar/alttab-windows-only` | Alt+Tab shows windows only (no Edge tabs) | immediate |
| `taskbar/no-snap-flyout` | No snap layouts flyout / snap suggestions (Win+arrow still works) | explorer restart |
| `taskbar/no-aero-shake` | Disable shake-to-minimize | immediate |
| `visual/drag-outline-only` | Dragging windows shows outline, not contents | sign out |
| `visual/instant-menus` | No menu open delay | sign out |
| `visual/no-minmax-animation` | No minimize/maximize animation | sign out |
| `visual/no-taskbar-animation` | No taskbar animations | explorer restart |
| `visual/no-transparency` | Disable transparency effects | immediate |
| `visual/dark-mode` | Dark mode for apps and system | immediate |
| `visual/wallpaper-full-quality` | Do not recompress JPEG wallpapers | re-set wallpaper |
| `visual/fast-shutdown` | Kill hung apps / apps blocking shutdown after 2s | sign out |
| `input/no-mouse-accel` | Disable 'Enhance pointer precision' | sign out |
| `input/fast-key-repeat` | Shortest key repeat delay, fastest rate | sign out |
| `input/no-sticky-keys-prompt` | No Sticky/Toggle/Filter Keys hotkey prompts (5x Shift etc.) | sign out |
| `input/no-layout-hotkey` | Disable Alt+Shift / Ctrl+Shift input language switching | sign out |
| `input/clipboard-history` | Enable clipboard history (Win+V) | immediate |
| `system/long-paths` | Allow paths longer than 260 chars | reboot, admin |
| `system/developer-mode` | Developer mode (unelevated symlinks, sideloading) | immediate, admin |
| `system/no-power-throttling` | Disable power throttling (EcoQoS) of background processes | reboot, admin |
| `system/no-fast-startup` | Disable Fast Startup (shutdown is a real shutdown) | next shutdown, admin |
| `system/hw-gpu-scheduling` | Hardware-accelerated GPU scheduling | reboot, admin |
| `system/verbose-status` | Verbose status messages at boot/sign-in/shutdown | next sign-in, admin |
| `system/utc-rtc` | Hardware clock is UTC (dual-boot with Linux only) | reboot, admin |
| `input/caps-to-backspace` | CapsLock -> Backspace, ScrollLock -> CapsLock | reboot, admin |
| `power/ultimate-performance` (`.ps1`) | Ultimate Performance plan (fallback High perf), AC: CPU min 5% (plan default is 100%), no USB suspend / PCIe ASPM / sleep | immediate |
