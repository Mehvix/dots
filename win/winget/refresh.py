#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Refresh the tracked winget package list.

Runs `winget export`, then reconciles the installed set against the tracked
list (`packages.json`):

  * packages tracked but no longer installed   -> prompted: reinstall / drop / ignore / skip
  * packages installed but not tracked         -> prompted: add / ignore / skip
  * transitive deps / OS runtimes              -> filtered silently
  * ignored packages (`.ignore`)               -> never prompted again

`.ignore` is a local, git-untracked file: one PackageIdentifier per line.
"Ignore" at the prompt appends there, so a package you don't want to track
stops resurfacing on every refresh.

    ./refresh.py            # reconcile, prompt on new + removed finds
    ./refresh.py -n         # dry run: report only, write nothing
    ./refresh.py -y         # add every new find, keep every removed one, no prompt
    ./refresh.py --setup-startup  # configure startup shortcuts for marked packages
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
TRACKED = HERE / "packages.json"
IGNORE = HERE / ".ignore"

# Transitive deps and OS-bundled runtimes winget installs on its own. Matched
# as prefixes against the PackageIdentifier. Reinstalling any real app pulls
# these back, so they're never worth tracking or prompting about.
DROP_PREFIXES = (
    "Microsoft.VCRedist",
    "Microsoft.VCLibs",
    "Microsoft.UI.Xaml",
    "Microsoft.DotNet.",
    "Microsoft.WindowsAppRuntime",
    "Microsoft.WinAppRuntime",
    "Microsoft.Winget.Source",
    "Microsoft.AppInstaller",
    "Microsoft.DesktopAppInstaller",
)

STARTUP_PACKAGES = {
    "hluk.CopyQ",
    "KeePassXCTeam.KeePassXC",
    "xanderfrangos.twinkletray",
    "ZhornSoftware.Caffeine",
}

EXE_NAME_MAP = {
    "hluk.CopyQ": "copyq.exe",
    "xanderfrangos.twinkletray": "twinkle-tray.exe",
}


def die(msg: str) -> None:
    print(f"refresh: {msg}", file=sys.stderr)
    sys.exit(1)


def is_dep(pid: str) -> bool:
    return any(pid.startswith(pre) for pre in DROP_PREFIXES)


def export_ids() -> list[str]:
    """Run `winget export` and return the flat list of PackageIdentifiers."""
    with tempfile.TemporaryDirectory() as td:
        out = Path(td) / "export.json"
        proc = subprocess.run(
            ["winget", "export", "-o", str(out), "--accept-source-agreements"],
            capture_output=True,
            text=True,
        )
        if not out.exists():
            die(f"winget export produced no file\n{proc.stdout}\n{proc.stderr}")
        data = json.loads(out.read_text(encoding="utf-8-sig"))
    ids: list[str] = []
    for src in data.get("Sources", []):
        for p in src.get("Packages", []):
            if pid := p.get("PackageIdentifier"):
                ids.append(pid)
    return ids


def load_tracked() -> list[str]:
    if not TRACKED.exists():
        return []
    data = json.loads(TRACKED.read_text())
    # Support both old flat format and new winget export format
    if "ids" in data:
        return data["ids"]
    # Extract from winget export format
    ids: list[str] = []
    for src in data.get("Sources", []):
        for p in src.get("Packages", []):
            if pid := p.get("PackageIdentifier"):
                ids.append(pid)
    return ids


def load_ignore() -> list[str]:
    if not IGNORE.exists():
        return []
    return [
        ln.strip()
        for ln in IGNORE.read_text().splitlines()
        if ln.strip() and not ln.strip().startswith("#")
    ]


def write_tracked(ids: set[str]) -> None:
    """Write package IDs in winget export/import format."""
    from datetime import datetime, timezone

    data = {
        "$schema": "https://aka.ms/winget-packages.schema.2.0.json",
        "CreationDate": datetime.now(timezone.utc).isoformat(),
        "Sources": [
            {
                "Packages": [
                    {"PackageIdentifier": pkg_id}
                    for pkg_id in sorted(ids, key=str.lower)
                ],
                "SourceDetails": {
                    "Argument": "https://cdn.winget.microsoft.com/cache",
                    "Identifier": "Microsoft.Winget.Source_8wekyb3d8bbwe",
                    "Name": "winget",
                    "Type": "Microsoft.PreIndexed.Package"
                }
            }
        ],
        "WinGetVersion": "1.11.510"
    }

    TRACKED.write_text(
        json.dumps(data, indent=2) + "\n",
        encoding="utf-8",
    )


def write_ignore(ids: set[str]) -> None:
    header = "# winget IDs to never track. Local, not git-tracked.\n"
    body = "\n".join(sorted(ids, key=str.lower))
    IGNORE.write_text(header + body + ("\n" if body else ""), encoding="utf-8")


class Prompter:
    """Per-find prompt with all/quit stickiness."""

    def __init__(self, add_all: bool):
        self.add_all = add_all
        self.ignore_all = False

    def ask(self, pid: str) -> str:
        """Return 'add', 'ignore', or 'skip'."""
        if self.add_all:
            return "add"
        if self.ignore_all:
            return "ignore"
        while True:
            ans = input(
                f"new: {pid}\n"
                "  [a]dd / [i]gnore / [s]kip / [A]dd-all / [I]gnore-all / [q]uit: "
            ).strip()
            match ans:
                case "a" | "add":
                    return "add"
                case "i" | "ignore":
                    return "ignore"
                case "s" | "skip" | "":
                    return "skip"
                case "A":
                    self.add_all = True
                    return "add"
                case "I":
                    self.ignore_all = True
                    return "ignore"
                case "q" | "quit":
                    print("aborted; no files written")
                    sys.exit(130)


class RemovedPrompter:
    """Per-find prompt for tracked packages that are no longer installed."""

    def __init__(self, reinstall_all: bool):
        self.reinstall_all = reinstall_all
        self.drop_all = False
        self.ignore_all = False

    def ask(self, pid: str) -> str:
        """Return 'reinstall', 'drop', 'ignore', or 'skip'."""
        if self.reinstall_all:
            return "reinstall"
        if self.drop_all:
            return "drop"
        if self.ignore_all:
            return "ignore"
        while True:
            ans = input(
                f"removed: {pid}  (tracked, no longer installed)\n"
                "  [r]einstall / [d]rop / [i]gnore / [s]kip / [R]/[D]/[I]-all / [q]uit: "
            ).strip()
            match ans:
                case "r" | "reinstall":
                    return "reinstall"
                case "d" | "drop":
                    return "drop"
                case "i" | "ignore":
                    return "ignore"
                case "s" | "skip" | "":
                    return "skip"
                case "R":
                    self.reinstall_all = True
                    return "reinstall"
                case "D":
                    self.drop_all = True
                    return "drop"
                case "I":
                    self.ignore_all = True
                    return "ignore"
                case "q" | "quit":
                    print("aborted; no files written")
                    sys.exit(130)


def winget_install(pid: str) -> bool:
    """Install a package by id via winget. Returns True on success."""
    proc = subprocess.run(
        ["winget", "install", "--id", pid, "-e",
         "--accept-source-agreements", "--accept-package-agreements"],
    )
    return proc.returncode == 0


def setup_startup_shortcuts() -> int:
    """Create startup shortcuts for packages marked in STARTUP_PACKAGES."""
    import os
    import shutil

    startup_folder = Path(os.environ.get("APPDATA", "")) / "Microsoft" / "Windows" / "Start Menu" / "Programs" / "Startup"
    start_menu = Path(os.environ.get("APPDATA", "")) / "Microsoft" / "Windows" / "Start Menu" / "Programs"
    winget_packages = Path(os.environ.get("LOCALAPPDATA", "")) / "Microsoft" / "WinGet" / "Packages"

    if not startup_folder.exists():
        die(f"Startup folder not found: {startup_folder}")

    tracked = set(load_tracked())
    startup_needed = tracked & STARTUP_PACKAGES

    if not startup_needed:
        print("No tracked packages need startup configuration")
        return 0

    print(f"Configuring startup for {len(startup_needed)} package(s)...")

    shortcut_names = {
        # "hluk.CopyQ": "CopyQ.lnk",
        "KeePassXCTeam.KeePassXC": "KeePassXC.lnk",
        # "xanderfrangos.twinkletray": "Twinkle Tray.lnk",
        "ZhornSoftware.Caffeine": "Caffeine.lnk",
    }

    def find_exe_from_startup_init(pkg_id: str) -> Path | None:
        """Look for startup.init file in WinGet Packages to find exe location."""
        if not winget_packages.exists():
            return None

        for pkg_dir in winget_packages.iterdir():
            if not pkg_dir.is_dir():
                continue
            if not pkg_dir.name.startswith(pkg_id.replace(".", "_")):
                continue

            startup_init = pkg_dir / "startup.init"
            if not startup_init.exists():
                continue

            try:
                for line in startup_init.read_text().splitlines():
                    if line.startswith("exe_name="):
                        exe_name = line.split("=", 1)[1].strip()
                        exe_path = pkg_dir / exe_name
                        if exe_path.exists():
                            return exe_path
            except Exception:
                pass

        return None

    for pkg_id in sorted(startup_needed):
        shortcut_name = shortcut_names.get(pkg_id)
        if not shortcut_name:
            # Fallback: use last part of package ID
            shortcut_name = f"{pkg_id.split('.')[-1]}.lnk"

        # Look for the shortcut in Start Menu (recursively search subdirs too)
        shortcut_path = None

        # First check direct path
        if (start_menu / shortcut_name).exists():
            shortcut_path = start_menu / shortcut_name
        else:
            # Check subdirectories
            for subdir in start_menu.rglob(shortcut_name):
                if subdir.is_file():
                    shortcut_path = subdir
                    break

        if not shortcut_path:
            exe_path = find_exe_from_startup_init(pkg_id)

            if exe_path:
                dest_path = startup_folder / shortcut_name

                if dest_path.exists():
                    print(f"  = {pkg_id} (already configured)")
                    continue

                ps_script = f"""
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut('{dest_path}')
$Shortcut.TargetPath = '{exe_path}'
$Shortcut.WorkingDirectory = '{exe_path.parent}'
$Shortcut.Save()
"""
                result = subprocess.run(
                    ["powershell", "-NoProfile", "-Command", ps_script],
                    capture_output=True,
                    text=True,
                )

                if result.returncode == 0 and dest_path.exists():
                    print(f"  + {pkg_id} -> {shortcut_name}")
                else:
                    print(f"  - {pkg_id}: failed to create shortcut")
                    if result.stderr:
                        print(f"    {result.stderr.strip()}")
                continue

            print(f"  ! {pkg_id}: shortcut '{shortcut_name}' not found in Start Menu")
            continue

        dest_path = startup_folder / shortcut_name

        if dest_path.exists():
            print(f"  = {pkg_id} (already configured)")
            continue

        try:
            shutil.copy2(shortcut_path, dest_path)
            print(f"  + {pkg_id} -> {shortcut_name}")
        except Exception as e:
            print(f"  - {pkg_id}: failed to copy shortcut: {e}")

    return 0


def main() -> int:
    ap = argparse.ArgumentParser(prog="refresh", description=__doc__)
    ap.add_argument("-n", "--dry-run", action="store_true", help="report only, write nothing")
    ap.add_argument("-y", "--yes", action="store_true", help="add every new find without prompting")
    ap.add_argument("--setup-startup", action="store_true", help="configure Windows startup shortcuts for marked packages")
    args = ap.parse_args()

    if args.setup_startup:
        return setup_startup_shortcuts()

    exported = {p for p in export_ids() if not is_dep(p)}
    tracked = set(load_tracked())
    ignored = set(load_ignore())

    removed = sorted(tracked - exported - ignored, key=str.lower)  # tracked, no longer installed
    new = sorted(exported - tracked - ignored, key=str.lower)      # installed, unaccounted for

    if not new and not removed:
        print("up to date; nothing to reconcile")
        return 0

    if args.dry_run:
        for pid in removed:
            print(f"  - {pid}  (removed, would prompt)")
        for pid in new:
            print(f"  ? {pid}  (new, would prompt)")
        print(f"\ndry run: {len(new)} new, {len(removed)} removed; no files written")
        return 0

    if (new or removed) and not args.yes and not sys.stdin.isatty():
        die(f"{len(new)} new / {len(removed)} removed package(s) but stdin is not a TTY; "
            "use -y to accept defaults or -n to preview")

    to_drop: set[str] = set()      # removed pids to stop tracking
    to_add: set[str] = set()       # new pids to start tracking
    to_ignore: set[str] = set()    # pids to append to .ignore

    # Removed: reinstall to restore, drop from tracking, ignore (drop + .ignore),
    # or skip (leave tracked so it re-prompts next run). -y keeps them all tracked.
    removed_prompter = RemovedPrompter(reinstall_all=args.yes)
    for pid in removed:
        match removed_prompter.ask(pid):
            case "reinstall":
                if winget_install(pid):
                    print(f"  + {pid}  (reinstalled, kept tracked)")
                else:
                    print(f"  ! {pid}  (reinstall failed, kept tracked)")
            case "drop":
                to_drop.add(pid)
                print(f"  - {pid}  (dropped)")
            case "ignore":
                to_ignore.add(pid)
                print(f"  ~ {pid}  (ignored)")
            case "skip":
                print(f"  . {pid}  (skipped this run)")

    prompter = Prompter(add_all=args.yes)
    for pid in new:
        match prompter.ask(pid):
            case "add":
                to_add.add(pid)
                print(f"  + {pid}")
            case "ignore":
                to_ignore.add(pid)
                print(f"  ~ {pid}  (ignored)")
            case "skip":
                print(f"  . {pid}  (skipped this run)")

    final = (tracked - to_drop) | to_add
    write_tracked(final)
    print(f"\nwrote {TRACKED} ({len(final)} packages)")
    if to_ignore:
        write_ignore(ignored | to_ignore)
        print(f"wrote {IGNORE} ({len(ignored | to_ignore)} ignored)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
