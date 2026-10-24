# Plasma rice

## Tracked

`stow/plasma` contains the current KDE/GTK appearance:

- `kdeglobals`: custom dark palette, PT Mono fonts, Windows widget style,
  disabled animations, Kitty as terminal, and file-dialog preferences.
- `plasmarc`: Psion desktop theme.
- GTK 3/4 settings, color CSS and decoration assets; XSettings settings.
- Psion Plasma theme, look-and-feel package, color scheme, and Aurorae
  decorations (both `psion` and `Psion` are intentional upstream names).
- OSX-ElCap cursor assets, preserving their relative symlinks.

Third-party theme metadata and included licenses are preserved. The live
`kdeglobals` palette differs from the stock Psion color scheme: don't reapply
an entire global theme if you want to keep those overrides.

## Dependencies

Install Plasma 6 (including Aurorae and the Windows Qt widget style), Breeze
GTK, PT Mono, Kitty, and **buuf-icons-for-plasma**. The existing 46 MB Buuf
icon pack at `~/.local/share/icons/buuf-icons-for-plasma` is deliberately not
vendored. The Psion package's optional stock wallpaper/splash dependencies
are not vendored either; the current desktop uses solid RGB `57,61,110`.
The current lock-screen wallpaper is CommonalityGris, also not vendored.

GTK and XSettings currently record this machine's DPI/cursor sizing. Adjust
those on a different display.

## Install

From the repo root, preferably while logged out of Plasma:

```sh
stow --dir=stow --target="$HOME" --no-folding --simulate --verbose plasma
stow --dir=stow --target="$HOME" --no-folding plasma
```

Existing files must be backed up outside the repository and moved out of the
way first. Don't blindly use `--adopt`: it overwrites the package's versions
with the target machine's files. `--no-folding` keeps directories real so KDE
can't write newly generated files straight into the repository.

KWin and mouse configuration mix appearance with hardware-specific state, so
these files are **not** symlinked. Apply just the appearance keys:

```sh
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Psion
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme OSX-ElCap
kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 64
```

Log out/in to load the settings. No live shell restart is required during
installation. Monitor layouts/scaling, tiling UUIDs, mouse acceleration,
wallets, application history, and session state are intentionally not stowed.

## Panels and desktop

Raw `plasma-org.kde.plasma.desktop-appletsrc` and `plasmashellrc` snapshots
are intentionally not tracked. They are not needed for the Stow package and
can contain screen/activity IDs, resolution history, and widget state.

To recreate the panel through Plasma's Edit Mode:

- Bottom edge, non-floating, 44 px high.
- Widgets, left to right: Application Launcher, Pager, Icons-only Task
  Manager, Margins Separator, System Tray, Digital Clock, Show Desktop.
- Pinned apps: System Settings, file manager, Brave.
- Digital clock: 24-hour format, Monday as the first day of the week.
- Desktop wallpaper: solid RGB `57,61,110` on each screen.

This preserves the useful appearance details without copying another
machine's IDs or replacing its existing desktop layout.

## Updating

Review `git diff -- stow/plasma manual/plasma` after changing appearance.
KDE's atomic config writes can replace a symlink with a regular file. If a
setting stops appearing in Git, compare the live file against its version in
`stow/plasma`, copy the wanted changes into the package, back up/move the live
file, and stow again. Don't reset unrelated settings to force a clean diff.

When changing the panel, update the portable description above rather than
committing raw Plasma layout/session files.
