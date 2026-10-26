"""Custom kitty tab bar (tab_bar_style custom) in the tmux2k onedark palette, as slanted chips
like the tmux window tabs (the @tmux2k-window-list-*-sep glyphs): every tab is a solid
slant-capped segment (U+E0BA title U+E0BC) - the active tab in the tmux current-window blue, a
tab whose window rang the bell in the tmux notification colour, the rest in the
transparent_background_colors colour from kitty.conf. Adjacent caps interlock, so the
transparent slant between them is the gap. kitty fades cell backgrounds but never glyphs, so a
cap only matches its body when the body colour is fully opaque (hence @1 for that colour), and
nothing is drawn in the window's background colour.
The text is still tab_title_template (via draw_title), so {bell_symbol}/{activity_symbol} work.
The focused tab uses the SSH destination's entry in ~/.config/omp/host-colors (the same table
.profile uses for OMP_HOST_COLOR). Local tabs use OMP_HOST_COLOR or the local host's entry;
unknown SSH destinations use the current-window blue, never the client's host color.

SSH grouping uses the active window's foreground SSH process, not its title (applications
such as pi replace that). When 2+ tabs connect to the same destination, the host gets a grey
chip at the start of the bar. Only matching "host: " prefixes are removed from those titles;
application titles are left intact. A lone SSH tab keeps its prefix.

Layout is our own rather than kitty's even split: every tab is sized to its title, clamped to
[MIN_TAB, MAX_TAB] cells, and when they don't all fit the row scrolls to keep the active tab
on screen, with \u2039 / \u203a marking hidden tabs. Hidden tabs draw nothing (so they aren't clickable).
"""

import re
from collections import Counter
from os import environ
from os.path import basename
from pathlib import Path
from socket import gethostname

from kittens.ssh.utils import get_connection_data
from kitty.fast_data_types import Screen, get_boss, get_options
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title

CAP_L, CAP_R = "\ue0ba", "\ue0bc"   # solid slant caps
MORE_LEFT, MORE_RIGHT = "\u2039", "\u203a"   # ‹ ›
MIN_TAB, MAX_TAB = 14, 36   # cells per tab, including padding and both caps
DEFAULT = 0                 # cell colour "default": the (translucent) background


def rgb(hex_color: str) -> int:
    return as_rgb(int(hex_color.lstrip("#"), 16))


def load_host_colors() -> dict[str, str]:
    """Read the profile's shared table once; reloading kitty reloads the entries."""
    config_home = Path(environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    try:
        lines = (config_home / "omp/host-colors").read_text().splitlines()
    except OSError:
        return {}
    result = {}
    for line in lines:
        fields = line.split()
        if len(fields) >= 2 and not fields[0].startswith("#") and re.fullmatch(r"#[0-9a-fA-F]{6}", fields[1]):
            result[fields[0].lower()] = fields[1]
    return result


HOST_COLORS = load_host_colors()

# (background, foreground)
ACTIVE = (rgb("#61afef"), rgb("#2d3139"))    # fallback: tmux current window
INACTIVE_FG = rgb("#a1a8b6")                 # theme inactive_tab_foreground
ALERT = (rgb("#e06c75"), rgb("#2d3139"))     # bell: tmux ⚑ notification segment
DIVIDER = rgb("#5c6370")                     # scroll markers
CHIP = (rgb("#5c6370"), rgb("#2d3139"))      # shared-host chip at the bar's start

_offset: dict = {}     # os_window_id -> index of the first visible tab (kept across redraws)
_layout: tuple = ()    # (widths, first visible, end, chips, hosts) for the pass in progress


def inactive_bg() -> int:
    """Inactive tabs' colour: the first transparent_background_colors entry in kitty.conf (kept
    at @1 so the glyph caps match the body); the plain default background without one."""
    entries = get_options().transparent_background_colors
    return as_rgb(int(entries[0][0])) if entries else DEFAULT


def colors(tab: TabBarData) -> tuple:
    if tab.is_active:
        remote_host = host_of(tab)
        host = remote_host or gethostname().lower()
        color = HOST_COLORS.get(host, HOST_COLORS.get(host.split(".")[0], ""))
        if not remote_host:
            color = environ.get("OMP_HOST_COLOR") or color
        return (rgb(color), ACTIVE[1]) if re.fullmatch(r"#[0-9a-fA-F]{6}", color) else ACTIVE
    return ALERT if tab.needs_attention else (inactive_bg(), INACTIVE_FG)


def title_width(draw_data: DrawData, tab: TabBarData, index: int) -> int:
    scratch = Screen(None, 1, 512)
    draw_title(draw_data, scratch, tab, index, 0)
    return scratch.cursor.x


def host_of(tab: TabBarData) -> str:
    """Read the live SSH destination; title changes and remote programs cannot change it."""
    live_tab = get_boss().tab_for_id(tab.tab_id)
    window = live_tab.active_window if live_tab is not None else None
    if window is None:
        return ""
    # Kitty already knows how to find its SSH kitten, including run-shell wrappers.
    args = window.ssh_kitten_cmdline()
    if not args:
        args = next((p["cmdline"] for p in window.child.foreground_processes
                     if p["cmdline"] and basename(p["cmdline"][0]).lower() in ("ssh", "ssh.exe")), [])
    if not args:
        return ""  # No SSH in the foreground: do not retain a host after disconnecting.
    connection = get_connection_data(args, extra_args=("--kitten",))
    return connection.hostname.rsplit("@", 1)[-1].strip("[]").lower() if connection else ""


def strip_host(tab: TabBarData, host: str) -> TabBarData:
    """Remove only a matching prefix, never characters from an app's replacement title."""
    if host:
        # Shell integration uses the short hostname even for a fully qualified destination.
        for name in (host, host.split(".")[0]):
            prefix = f"{name}: "
            if tab.title[:len(prefix)].lower() == prefix:
                return tab._replace(title=tab.title[len(prefix):])
    return tab


def compute_layout(draw_data: DrawData, columns: int) -> tuple:
    tm = get_boss().os_window_map.get(draw_data.os_window_id)
    tabs = list(tm.tab_bar_data) if tm is not None else []
    hosts = [host_of(t) for t in tabs]
    counts = Counter(h for h in hosts if h)
    # hosts with 2+ tabs get a leading chip and are stripped from their tabs' titles
    chips = sorted((h for h, n in counts.items() if n > 1), key=lambda h: (-counts[h], hosts.index(h)))
    shown = [strip_host(t, h if h in chips else "") for t, h in zip(tabs, hosts)]
    chip_cells = sum(len(h) + 4 for h in chips) + bool(chips)   # caps+pads per chip + one gap
    # title + two pads + two caps
    widths = [min(MAX_TAB, max(MIN_TAB, title_width(draw_data, t, i + 1) + 4)) for i, t in enumerate(shown)]
    active = next((i for i, t in enumerate(tabs) if t.is_active), 0)
    room = columns - 2 - chip_cells            # leave space for the ‹ / › markers
    first = min(_offset.get(draw_data.os_window_id, 0), active)
    while first < active and sum(widths[first:active + 1]) > room:
        first += 1
    end, used = first, 0
    while end < len(widths) and used + widths[end] <= room:
        used += widths[end]
        end += 1
    _offset[draw_data.os_window_id] = first
    return widths, first, max(end, active + 1), chips, hosts


def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData, before: int,
    max_tab_length: int, index: int, is_last: bool, extra_data: ExtraData,
) -> int:
    global _layout
    if index == 1 or not _layout:
        _layout = compute_layout(draw_data, screen.columns)
    widths, first, end, chips, hosts = _layout
    i = index - 1
    c = screen.cursor
    c.bold = c.italic = False       # kitty sets per-tab font flags before calling us
    if index == 1:                 # the shared-host chip(s) head the bar, even if tab 1 scrolled off
        for h in chips:
            c.fg, c.bg = CHIP[0], DEFAULT
            screen.draw(CAP_L)
            c.fg, c.bg = CHIP[1], CHIP[0]
            c.bold = True
            screen.draw(f" {h} ")
            c.bold = False
            c.fg, c.bg = CHIP[0], DEFAULT
            screen.draw(CAP_R)
        if chips:
            screen.draw(" ")
    if i < first:                  # scrolled off to the left
        return c.x
    if i >= end:                   # scrolled off to the right: mark it once
        if i == end:
            c.fg, c.bg = DIVIDER, DEFAULT
            screen.draw(MORE_RIGHT)
        return c.x
    if i == first and first > 0:
        c.fg, c.bg = DIVIDER, DEFAULT
        screen.draw(MORE_LEFT + " ")

    width = widths[i] if i < len(widths) else MIN_TAB
    if i < len(hosts) and hosts[i] in chips:
        tab = strip_host(tab, hosts[i])
    bg, fg = colors(tab)

    start = c.x
    c.fg, c.bg = bg, DEFAULT
    screen.draw(CAP_L)
    c.fg, c.bg = fg, bg
    c.bold, c.italic = tab.is_active, False
    screen.draw(" ")
    body = start + width - 1       # the last cell is the right cap
    draw_title(draw_data, screen, tab, index, max(1, body - c.x - 1))
    if c.x > body - 1:             # still too long: back up and end with an ellipsis
        c.x = body - 2
        screen.draw("…")
    while c.x < body:              # pad short titles out to the tab's width
        screen.draw(" ")
    c.bold = c.italic = False
    c.fg, c.bg = bg, DEFAULT
    screen.draw(CAP_R)
    return c.x
