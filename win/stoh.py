#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""stoh — stow-like config tracker for Windows.

Each package is a directory under win/ with a `.stoh` manifest. The manifest
chooses what to install where:

  Shorthand (one bare line) — whole package -> target:
    %USERPROFILE%

  Long form:
    source = ../stow/system     # optional; defaults to the package dir
    target = %USERPROFILE%      # whole-source target
    # OR per-subdir mappings:
    roaming = %APPDATA%
    local   = %LOCALAPPDATA%

`collect` pulls live files into the source tree; `install` pushes them out;
`evict` drops files that git ignores.
"""

from __future__ import annotations

import argparse
import filecmp
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

WIN_DIR = Path(__file__).resolve().parent
MANIFEST = ".stoh"


def expand(path: str) -> Path:
    """Expand $VAR and %VAR% on any platform, then ~."""
    s = os.path.expandvars(path)
    # Also handle %VAR% on posix (expandvars there only does $VAR).
    while "%" in s:
        start = s.find("%")
        end = s.find("%", start + 1)
        if end == -1:
            break
        var = s[start + 1 : end]
        val = os.environ.get(var)
        if val is None:
            break
        s = s[:start] + val + s[end + 1 :]
    return Path(os.path.expanduser(s))


@dataclass
class Mapping:
    """A (subpath under source) -> (target root) mapping."""

    subpath: str  # "" means whole source tree
    target: Path
    source: Path  # already-resolved root to copy *from*

    def src_root(self) -> Path:
        return self.source if self.subpath == "" else self.source / self.subpath

    def dst_root(self) -> Path:
        return self.target if self.subpath == "" else self.target / self.subpath


# Reserved manifest keys that don't define a subpath mapping.
RESERVED_KEYS = {"source", "target"}


def parse_manifest(pkg_dir: Path) -> list[Mapping]:
    """Parse `.stoh`. Grammar:

      Whole-package shorthand (one bare line):
        %USERPROFILE%

      Long form (any combination):
        source = ../stow/system     # optional; defaults to package dir
        target = %USERPROFILE%      # whole-package target
        <subdir> = <path>           # per-subdir target (mutually exclusive with `target`)
    """
    mf = pkg_dir / MANIFEST
    if not mf.exists():
        die(f"missing manifest: {mf}")
    lines = [
        ln.strip()
        for ln in mf.read_text().splitlines()
        if ln.strip() and not ln.strip().startswith("#")
    ]
    if not lines:
        die(f"empty manifest: {mf}")

    # Shorthand: single bare line == whole package -> that target.
    if len(lines) == 1 and "=" not in lines[0]:
        return [Mapping("", expand(lines[0]), pkg_dir)]

    pkg_source: Path = pkg_dir
    pkg_target: Path | None = None
    subs: list[tuple[str, str]] = []
    for ln in lines:
        if "=" not in ln:
            die(f"{mf}: expected key=value, got: {ln}")
        k, v = (s.strip() for s in ln.split("=", 1))
        if k == "source":
            pkg_source = (pkg_dir / expand(v)).resolve()
            if not pkg_source.is_dir():
                die(f"{mf}: source not a directory: {pkg_source}")
            continue
        if k == "target":
            pkg_target = expand(v)
            continue
        if not k or k in (".", ".."):
            die(f"{mf}: bad key: {k!r}")
        subs.append((k, v))

    if pkg_target is not None and subs:
        die(f"{mf}: cannot mix 'target=' with per-subdir mappings")
    if pkg_target is not None:
        return [Mapping("", pkg_target, pkg_source)]
    if not subs:
        die(f"{mf}: no target specified")
    mappings: list[Mapping] = []
    for k, v in subs:
        sub = pkg_source / k
        if sub.exists() and not sub.is_dir():
            die(f"{mf}: {k} exists in source but is not a directory")
        mappings.append(Mapping(k, expand(v), pkg_source))
    return mappings


def list_packages() -> list[Path]:
    return sorted(
        p for p in WIN_DIR.iterdir() if p.is_dir() and (p / MANIFEST).exists()
    )


def resolve_packages(names: list[str], all_flag: bool) -> list[Path]:
    if all_flag:
        return list_packages()
    if not names:
        die("specify package(s) or use --all")
    out = []
    for n in names:
        p = WIN_DIR / n
        if not p.is_dir():
            die(f"no such package: {n}")
        if not (p / MANIFEST).exists():
            die(f"package missing manifest: {n}/{MANIFEST}")
        out.append(p)
    return out


def walk_files(root: Path) -> list[Path]:
    """All files under root, excluding .stoh manifests and .git internals."""
    files: list[Path] = []
    if not root.exists():
        return files
    for p in root.rglob("*"):
        if p.is_file() and p.name != MANIFEST and ".git" not in p.parts:
            files.append(p)
    return files


# ---------- conflict prompt ----------


class Prompter:
    def __init__(self, force: bool, dry: bool):
        self.force = force
        self.dry = dry
        self.yes_all = False
        self.no_all = False

    def confirm_overwrite(self, src: Path, dst: Path) -> bool:
        if self.force or self.yes_all:
            return True
        if self.no_all:
            return False
        while True:
            print(f"\nconflict: {dst}")
            print(f"  source: {src}")
            ans = input("  overwrite? [y]es / [n]o / [a]ll / [s]kip-all / [d]iff / [q]uit: ").strip().lower()
            if ans in ("y", "yes"):
                return True
            if ans in ("n", "no"):
                return False
            if ans == "a":
                self.yes_all = True
                return True
            if ans == "s":
                self.no_all = True
                return False
            if ans == "d":
                show_diff(src, dst)
                continue
            if ans == "q":
                sys.exit(130)


def show_diff(a: Path, b: Path) -> None:
    try:
        ta = a.read_text(encoding="utf-8").splitlines()
        tb = b.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        print("  (binary, skipping diff)")
        return
    import difflib

    for line in difflib.unified_diff(tb, ta, fromfile=str(b), tofile=str(a), lineterm=""):
        print("  " + line)


# ---------- commands ----------


def cmd_install(pkgs: list[Path], prompter: Prompter) -> int:
    n_copied = n_skipped = n_same = 0
    for pkg in pkgs:
        for m in parse_manifest(pkg):
            src_root = m.src_root()
            dst_root = m.dst_root()
            if not src_root.exists():
                print(f"[{pkg.name}] skip: {src_root} (no source)")
                continue
            for src in walk_files(src_root):
                rel = src.relative_to(src_root)
                dst = dst_root / rel
                if dst.exists() and dst.is_file():
                    if filecmp.cmp(src, dst, shallow=False):
                        n_same += 1
                        continue
                    if not prompter.confirm_overwrite(src, dst):
                        print(f"  skip {dst}")
                        n_skipped += 1
                        continue
                action = f"would copy" if prompter.dry else "copy"
                print(f"  {action} {src} -> {dst}")
                if not prompter.dry:
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src, dst)
                n_copied += 1
    print(f"\ninstall: {n_copied} copied, {n_skipped} skipped, {n_same} unchanged")
    return 0


def cmd_collect(pkgs: list[Path], prompter: Prompter) -> int:
    """Refresh tracked files from live system. Only files already present in pkg are pulled."""
    n_copied = n_skipped = n_same = n_missing = 0
    for pkg in pkgs:
        for m in parse_manifest(pkg):
            src_root = m.src_root()
            dst_root = m.dst_root()
            for tracked in walk_files(src_root):
                rel = tracked.relative_to(src_root)
                live = dst_root / rel
                if not live.exists():
                    print(f"  missing on disk: {live}")
                    n_missing += 1
                    continue
                if filecmp.cmp(tracked, live, shallow=False):
                    n_same += 1
                    continue
                # live differs from tracked — pull live in
                if not prompter.confirm_overwrite(live, tracked):
                    print(f"  keep {tracked}")
                    n_skipped += 1
                    continue
                action = f"would pull" if prompter.dry else "pull"
                print(f"  {action} {live} -> {tracked}")
                if not prompter.dry:
                    shutil.copy2(live, tracked)
                n_copied += 1
    print(
        f"\ncollect: {n_copied} pulled, {n_skipped} kept, {n_same} unchanged, {n_missing} missing-on-disk"
    )
    return 0


def cmd_status(pkgs: list[Path]) -> int:
    for pkg in pkgs:
        print(f"=== {pkg.name} ===")
        for m in parse_manifest(pkg):
            src_root = m.src_root()
            dst_root = m.dst_root()
            print(f"  {m.subpath or '.'} -> {dst_root}")
            for tracked in walk_files(src_root):
                rel = tracked.relative_to(src_root)
                live = dst_root / rel
                if not live.exists():
                    state = "missing"
                elif filecmp.cmp(tracked, live, shallow=False):
                    state = "ok"
                else:
                    state = "differs"
                print(f"    [{state}] {rel}")
    return 0


def cmd_evict(pkgs: list[Path], dry: bool) -> int:
    """Remove files from each package's source tree that git ignores."""
    repo_root = WIN_DIR.parent
    if not (repo_root / ".git").exists():
        die("evict: not in a git working tree")
    n_evicted = 0
    # collect distinct source roots (multiple mappings may share one)
    roots: list[Path] = []
    for pkg in pkgs:
        for m in parse_manifest(pkg):
            r = m.src_root()
            if r not in roots:
                roots.append(r)
    for root in roots:
        try:
            root.relative_to(repo_root)
        except ValueError:
            print(f"  skip {root} (outside repo)")
            continue
        files = walk_files(root)
        if not files:
            continue
        rels = [str(f.relative_to(repo_root)) for f in files]
        proc = subprocess.run(
            ["git", "check-ignore", "--stdin"],
            input="\n".join(rels),
            text=True,
            capture_output=True,
            cwd=repo_root,
        )
        ignored = set(proc.stdout.splitlines())
        for f, rel in zip(files, rels):
            if rel in ignored or rel.replace("\\", "/") in ignored:
                action = "would evict" if dry else "evict"
                print(f"  {action} {f}")
                if not dry:
                    f.unlink()
                n_evicted += 1
        if not dry:
            for d in sorted(
                (p for p in root.rglob("*") if p.is_dir()),
                key=lambda p: len(p.parts),
                reverse=True,
            ):
                try:
                    d.rmdir()
                except OSError:
                    pass
    print(f"\nevict: {n_evicted} file(s)")
    return 0


def cmd_list() -> int:
    for pkg in list_packages():
        ms = parse_manifest(pkg)
        redirected = ms[0].source != pkg
        suffix = f"  (source: {ms[0].source})" if redirected else ""
        if len(ms) == 1 and ms[0].subpath == "":
            print(f"  {pkg.name} -> {ms[0].target}{suffix}")
        else:
            print(f"  {pkg.name}{suffix}")
            for m in ms:
                print(f"    {m.subpath} -> {m.target}")
    return 0


def die(msg: str) -> None:
    print(f"stoh: {msg}", file=sys.stderr)
    sys.exit(1)


def main() -> int:
    ap = argparse.ArgumentParser(prog="stoh", description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)

    def add_pkg_args(p: argparse.ArgumentParser) -> None:
        p.add_argument("packages", nargs="*")
        p.add_argument("--all", action="store_true", help="operate on every package")
        p.add_argument("-n", "--dry-run", action="store_true")
        p.add_argument("-f", "--force", action="store_true", help="overwrite without prompting")

    add_pkg_args(sub.add_parser("install", help="copy package files onto the system"))
    add_pkg_args(sub.add_parser("collect", help="pull live files back into the package"))

    p_status = sub.add_parser("status", help="show diff/missing per tracked file")
    p_status.add_argument("packages", nargs="*")
    p_status.add_argument("--all", action="store_true")

    p_evict = sub.add_parser("evict", help="remove gitignored files from packages")
    p_evict.add_argument("packages", nargs="*")
    p_evict.add_argument("--all", action="store_true")
    p_evict.add_argument("-n", "--dry-run", action="store_true")

    sub.add_parser("list", help="list packages and their manifests")

    args = ap.parse_args()

    if args.cmd == "list":
        return cmd_list()

    pkgs = (
        []
        if args.cmd not in ("install", "collect", "status", "evict")
        else resolve_packages(getattr(args, "packages", []), getattr(args, "all", False))
    )

    if args.cmd == "install":
        return cmd_install(pkgs, Prompter(args.force, args.dry_run))
    if args.cmd == "collect":
        return cmd_collect(pkgs, Prompter(args.force, args.dry_run))
    if args.cmd == "status":
        return cmd_status(pkgs)
    if args.cmd == "evict":
        return cmd_evict(pkgs, args.dry_run)
    die(f"unknown command: {args.cmd}")
    return 2


if __name__ == "__main__":
    sys.exit(main())
