#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Refresh the tracked winget package list.

Runs `winget export`, then reconciles the installed set against the tracked
list (`packages.json`):

  * packages tracked but no longer installed  -> dropped (reported)
  * packages installed but not tracked         -> prompted: add / ignore / skip
  * transitive deps / OS runtimes              -> filtered silently
  * ignored packages (`.ignore`)               -> never prompted again

`.ignore` is a local, git-untracked file: one PackageIdentifier per line.
"Ignore" at the prompt appends there, so a package you don't want to track
stops resurfacing on every refresh.

    ./refresh.py            # reconcile, prompt on new finds
    ./refresh.py -n         # dry run: report only, write nothing
    ./refresh.py -y         # add every new find, no prompt
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
    return json.loads(TRACKED.read_text())["ids"]


def load_ignore() -> list[str]:
    if not IGNORE.exists():
        return []
    return [
        ln.strip()
        for ln in IGNORE.read_text().splitlines()
        if ln.strip() and not ln.strip().startswith("#")
    ]


def write_tracked(ids: set[str]) -> None:
    TRACKED.write_text(
        json.dumps({"ids": sorted(ids, key=str.lower)}, indent=2) + "\n",
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


def main() -> int:
    ap = argparse.ArgumentParser(prog="refresh", description=__doc__)
    ap.add_argument("-n", "--dry-run", action="store_true", help="report only, write nothing")
    ap.add_argument("-y", "--yes", action="store_true", help="add every new find without prompting")
    args = ap.parse_args()

    exported = {p for p in export_ids() if not is_dep(p)}
    tracked = set(load_tracked())
    ignored = set(load_ignore())

    removed = tracked - exported                       # tracked, no longer installed
    new = sorted(exported - tracked - ignored, key=str.lower)  # installed, unaccounted for

    for pid in sorted(removed, key=str.lower):
        print(f"  - {pid}  (no longer installed)")

    if not new and not removed:
        print("up to date; nothing to reconcile")
        return 0

    if args.dry_run:
        for pid in new:
            print(f"  ? {pid}  (new, would prompt)")
        print(f"\ndry run: {len(new)} new, {len(removed)} removed; no files written")
        return 0

    if new and not args.yes and not sys.stdin.isatty():
        die(f"{len(new)} new package(s) but stdin is not a TTY; use -y to add all or -n to preview")

    prompter = Prompter(add_all=args.yes)
    to_add: set[str] = set()
    to_ignore: set[str] = set()
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

    final = (tracked - removed) | to_add
    write_tracked(final)
    print(f"\nwrote {TRACKED} ({len(final)} packages)")
    if to_ignore:
        write_ignore(ignored | to_ignore)
        print(f"wrote {IGNORE} ({len(ignored | to_ignore)} ignored)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
