#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = ["textual>=0.48", "croniter"]
# ///
"""crontui: minimal TUI to view and manage THIS host's user crontab.

Disabled jobs are kept in the crontab as '#OFF# <original line>', so re-enabling
restores the line byte-for-byte. Comment lines directly above a job are its
description. Every write backs up the previous crontab to ~/.crontui/backups/.
"""
import os
import re
import shlex
import socket
import subprocess
import tempfile
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from croniter import croniter
from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.screen import ModalScreen, Screen
from textual.widgets import DataTable, Footer, Header, Label, Log, Static

OFF = "#OFF# "
STATE_DIR = Path.home() / ".crontui"
HOST = socket.gethostname().split(".")[0]
ENV_RE = re.compile(r"^\s*[A-Za-z_][A-Za-z0-9_]*\s*=")
REDIR_RE = re.compile(r"(\d?)>>?\s*([^\s;&|<>]+)")
TEMPLATE_HELP = (
    "## crontui: one job line, optionally preceded by '# description' lines.\n"
    "## Schedule: m h dom mon dow (or @daily/@weekly/@reboot ...). '##' lines are dropped.\n"
    "## Save unchanged or empty to cancel.\n"
)
ADD_TEMPLATE = TEMPLATE_HELP + "# description\n0 3 * * * /path/to/cmd >> /path/to/log 2>&1\n"


@dataclass
class Line:
    raw: str
    job: bool = False
    enabled: bool = True
    sched: str = ""
    cmd: str = ""


def parse_line(raw):
    enabled = not raw.startswith(OFF)
    body = raw if enabled else raw[len(OFF):]
    s = body.strip()
    if not s or (enabled and (s.startswith("#") or ENV_RE.match(s))):
        return Line(raw)
    if s.startswith("@"):
        parts = s.split(None, 1)
        if len(parts) < 2:
            return Line(raw)
        sched, cmd = parts
    else:
        parts = s.split(None, 5)
        if len(parts) < 6:
            return Line(raw)
        sched, cmd = " ".join(parts[:5]), parts[5]
    return Line(raw, True, enabled, sched, cmd)


def is_comment(line):
    return not line.job and line.raw.lstrip().startswith("#")


def description(lines, i):
    """(first index of the job's description block, description lines)."""
    start = i
    while start > 0 and is_comment(lines[start - 1]):
        start -= 1
    return start, [l.raw.lstrip().lstrip("#").strip() for l in lines[start:i]]


def valid_sched(sched):
    return sched == "@reboot" or croniter.is_valid(sched)


def next_run(line):
    if not line.enabled or line.sched == "@reboot":
        return "—"
    try:
        return croniter(line.sched, datetime.now()).get_next(datetime).strftime("%a %m-%d %H:%M")
    except Exception:
        return "invalid"


def log_path(cmd):
    """First stdout redirect target in the command, resolved like cron would (cwd=$HOME)."""
    for fd, p in REDIR_RE.findall(cmd):
        if fd in ("", "1") and p != "/dev/null":
            return Path.home() / os.path.expandvars(os.path.expanduser(p))
    return None


def tail(path, n):
    try:
        with open(path, "rb") as f:
            f.seek(0, 2)
            f.seek(max(0, f.tell() - 256 * 1024))
            return f.read().decode(errors="replace").splitlines()[-n:]
    except OSError as e:
        return [f"<{e.strerror}: {path}>"]


def read_crontab():
    r = subprocess.run(["crontab", "-l"], capture_output=True, text=True)
    if r.returncode != 0:
        if "no crontab" in r.stderr:
            return ""
        raise RuntimeError(r.stderr.strip())
    return r.stdout


def write_crontab(new, expected_old):
    cur = read_crontab()
    if cur != expected_old:
        raise RuntimeError("crontab changed outside crontui; reloaded, nothing written")
    backups = STATE_DIR / "backups"
    backups.mkdir(parents=True, exist_ok=True)
    (backups / f"crontab.{HOST}.{datetime.now():%Y%m%d-%H%M%S-%f}").write_text(cur)
    r = subprocess.run(["crontab", "-"], input=new, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"crontab rejected the change: {r.stderr.strip()}")
    if read_crontab() != new:
        raise RuntimeError("crontab -l doesn't match what was written")


def parse_block(text):
    """Editor text -> list of Lines (comments + exactly one job), or an error string."""
    block = [parse_line(r) for r in text.splitlines()
             if r.strip() and not r.lstrip().startswith("##")]
    jobs = [l for l in block if l.job]
    if len(jobs) != 1:
        return f"expected exactly one job line, got {len(jobs)}"
    if any(not l.job and not is_comment(l) for l in block):
        return "only '# comment' lines are allowed besides the job line"
    if not valid_sched(jobs[0].sched):
        return f"invalid schedule: {jobs[0].sched!r}"
    if not block[-1].job:
        return "the job line must come last (description comments go above it)"
    return block


class Confirm(ModalScreen):
    BINDINGS = [("y", "yes", "Yes"), ("n,escape", "no", "No")]

    def __init__(self, msg):
        super().__init__()
        self.msg = msg

    def compose(self) -> ComposeResult:
        yield Label(Text(f"{self.msg}\n\n[y]es / [n]o"), id="confirm")

    def action_yes(self):
        self.dismiss(True)

    def action_no(self):
        self.dismiss(False)


class LogView(Screen):
    BINDINGS = [("escape,q,l", "app.pop_screen", "Back")]

    def __init__(self, path):
        super().__init__()
        self.path = path

    def compose(self) -> ComposeResult:
        yield Header()
        yield Log()
        yield Footer()

    def on_mount(self):
        self.sub_title = f"{HOST}: {self.path}"
        self.reload()
        self.set_interval(2, self.reload)

    def reload(self):
        log = self.query_one(Log)
        log.clear()
        log.write_lines(tail(self.path, 500))


class CronTUI(App):
    TITLE = "crontui"
    CSS = """
    DataTable { height: 1fr; }
    #detail { height: 16; border-top: solid $accent; padding: 0 1; }
    Confirm { align: center middle; }
    #confirm { border: thick $warning; padding: 1 2; width: 80; background: $surface; }
    """
    BINDINGS = [
        Binding("space", "toggle", "On/Off"),
        Binding("r", "run", "Run now"),
        Binding("l", "log", "Log"),
        Binding("e", "edit", "Edit"),
        Binding("a", "add", "Add"),
        Binding("d", "delete", "Delete"),
        Binding("R", "reload", "Reload"),
        Binding("q", "quit", "Quit"),
    ]

    def compose(self) -> ComposeResult:
        yield Header()
        yield DataTable(cursor_type="row", zebra_stripes=True)
        yield Static(id="detail")
        yield Footer()

    def on_mount(self):
        self.query_one(DataTable).add_columns("", "Schedule", "Next run", "Description", "Command")
        self.action_reload()

    # --- model <-> view ---
    def action_reload(self):
        try:
            self.text = read_crontab()
        except RuntimeError as e:
            self.text = ""
            self.notify(str(e), severity="error")
        self.lines = [parse_line(r) for r in self.text.splitlines()]
        table = self.query_one(DataTable)
        row = table.cursor_row
        table.clear()
        jobs = [(i, l) for i, l in enumerate(self.lines) if l.job]
        for i, l in jobs:
            desc = description(self.lines, i)[1]
            table.add_row(
                Text("✓", "green") if l.enabled else Text("✗", "red"),
                l.sched, next_run(l), desc[0] if desc else "",
                l.cmd if len(l.cmd) <= 60 else l.cmd[:59] + "…",
                key=str(i),
            )
        off = sum(not l.enabled for _, l in jobs)
        self.sub_title = f"crontab @ {HOST} — {len(jobs)} jobs, {off} off"
        if jobs:
            table.move_cursor(row=min(row, len(jobs) - 1))
        self.show_detail()

    def selected(self):
        table = self.query_one(DataTable)
        if not table.row_count:
            return None
        return int(table.coordinate_to_cell_key(table.cursor_coordinate).row_key.value)

    def on_data_table_row_highlighted(self, _event):
        self.show_detail()

    def show_detail(self):
        i = self.selected()
        detail = self.query_one("#detail", Static)
        if i is None:
            detail.update(Text(f"No jobs in {HOST}'s crontab. Press 'a' to add one."))
            return
        l = self.lines[i]
        t = Text()
        for d in description(self.lines, i)[1]:
            t.append(f"{d}\n", "italic")
        t.append(f"{l.sched}  ", "bold")
        t.append(f"{'enabled' if l.enabled else 'DISABLED'}  next: {next_run(l)}\n",
                 "green" if l.enabled else "red")
        t.append(f"{l.cmd}\n")
        p = log_path(l.cmd)
        if p is None:
            t.append("log: (no >> redirect in command)\n", "dim")
        else:
            mtime = time.strftime("%Y-%m-%d %H:%M", time.localtime(p.stat().st_mtime)) if p.exists() else "missing"
            t.append(f"log: {p}  (modified {mtime})\n", "dim")
            for line in tail(p, 8):
                t.append(f"  {line}\n", "dim")
        detail.update(t)

    def save(self, lines):
        new = "\n".join(l.raw for l in lines) + "\n" if lines else ""
        try:
            write_crontab(new, self.text)
        except RuntimeError as e:
            self.notify(str(e), severity="error", timeout=10)
        self.action_reload()

    # --- actions ---
    def action_toggle(self):
        i = self.selected()
        if i is None:
            return
        lines = list(self.lines)
        raw = lines[i].raw
        lines[i] = Line(raw[len(OFF):] if raw.startswith(OFF) else OFF + raw)
        self.save(lines)

    def action_run(self):
        i = self.selected()
        if i is None:
            return
        cmd = self.lines[i].cmd
        if re.search(r"(?<!\\)%", cmd):
            self.notify("command uses cron's '%' (newline/stdin) syntax; run it by hand", severity="warning")
            return
        cmd = cmd.replace("\\%", "%")

        def go(ok):
            if not ok:
                return
            STATE_DIR.mkdir(exist_ok=True)
            out = STATE_DIR / f"run-{HOST}.log"
            with open(out, "a") as f:
                f.write(f"=== {time.strftime('%F %T')} {cmd}\n")
                f.flush()
                proc = subprocess.Popen(["bash", "-c", cmd], cwd=Path.home(), stdin=subprocess.DEVNULL,
                                        stdout=f, stderr=subprocess.STDOUT, start_new_session=True)
            self.notify(f"started pid {proc.pid}; unredirected output -> {out}")

        self.push_screen(Confirm(f"Run now on {HOST}?\n\n{cmd}"), go)

    def action_log(self):
        i = self.selected()
        if i is None:
            return
        p = log_path(self.lines[i].cmd)
        if p is None:
            self.notify("no >> log redirect in this command", severity="warning")
        else:
            self.push_screen(LogView(p))

    def edit_in_editor(self, initial):
        with tempfile.NamedTemporaryFile("w", prefix="crontui-", suffix=".cron", delete=False) as f:
            f.write(initial)
        editor = os.environ.get("VISUAL") or os.environ.get("EDITOR") or "vi"
        try:
            with self.suspend():
                subprocess.call(shlex.split(editor) + [f.name])
            return Path(f.name).read_text()
        finally:
            os.unlink(f.name)

    def edit_block(self, initial):
        """Open the editor; return parsed Lines, or None if cancelled/invalid."""
        text = self.edit_in_editor(initial)
        if text == initial or not text.strip():
            self.notify("cancelled")
            return None
        block = parse_block(text)
        if isinstance(block, str):
            self.notify(f"{block}; nothing written", severity="error", timeout=10)
            return None
        return block

    def action_edit(self):
        i = self.selected()
        if i is None:
            return
        start = description(self.lines, i)[0]
        initial = TEMPLATE_HELP + "".join(l.raw + "\n" for l in self.lines[start:i + 1])
        block = self.edit_block(initial)
        if block is not None:
            self.save(self.lines[:start] + block + self.lines[i + 1:])

    def action_add(self):
        block = self.edit_block(ADD_TEMPLATE)
        if block is None:
            return
        lines = list(self.lines)
        if lines and lines[-1].raw.strip():
            lines.append(Line(""))
        self.save(lines + block)
        table = self.query_one(DataTable)
        table.move_cursor(row=table.row_count - 1)

    def action_delete(self):
        i = self.selected()
        if i is None:
            return
        start = description(self.lines, i)[0]

        def go(ok):
            if not ok:
                return
            lines = self.lines[:start] + self.lines[i + 1:]
            # drop the blank separator a deleted trailing/isolated job leaves behind
            if start > 0 and not lines[start - 1].raw.strip() and (start >= len(lines) or not lines[start].raw.strip()):
                del lines[start - 1]
            self.save(lines)

        self.push_screen(Confirm(f"Delete from {HOST}'s crontab?\n\n{self.lines[i].raw}"), go)


if __name__ == "__main__":
    CronTUI().run()
