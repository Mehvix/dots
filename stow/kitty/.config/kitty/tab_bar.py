"""Custom kitty tab bar (tab_bar_style custom) in the tmux2k onedark palette, as slanted chips
like the tmux window tabs (the @tmux2k-window-list-*-sep glyphs): every tab is a solid
slant-capped segment (U+E0BA title U+E0BC) - the active tab in the tmux current-window blue, a
tab whose window rang the bell in the tmux notification colour, the rest in the
transparent_background_colors colour from kitty.conf. Adjacent caps interlock, so the
transparent slant between them is the gap. kitty fades cell backgrounds but never glyphs, so a
cap only matches its body when the body colour is fully opaque (hence @1 for that colour), and
nothing is drawn in the window's background colour.
The text is still tab_title_template (via draw_title), so {bell_symbol}/{activity_symbol} work.

Layout is our own rather than kitty's even split: every tab is sized to its title, clamped to
[MIN_TAB, MAX_TAB] cells, and when they don't all fit the row scrolls to keep the active tab
on screen, with \u2039 / \u203a marking hidden tabs. Hidden tabs draw nothing (so they aren't clickable).
"""

from kitty.fast_data_types import Screen, get_boss, get_options
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title

CAP_L, CAP_R = "\ue0ba", "\ue0bc"   # solid slant caps
MORE_LEFT, MORE_RIGHT = "\u2039", "\u203a"   # ‹ ›
MIN_TAB, MAX_TAB = 14, 36   # cells per tab, including padding and both caps
DEFAULT = 0                 # cell colour "default": the (translucent) background


def rgb(hex_color: str) -> int:
    return as_rgb(int(hex_color.lstrip("#"), 16))


# (background, foreground)
ACTIVE = (rgb("#61afef"), rgb("#2d3139"))    # tmux current window
INACTIVE_FG = rgb("#a1a8b6")                 # theme inactive_tab_foreground
ALERT = (rgb("#e06c75"), rgb("#2d3139"))     # bell: tmux ⚑ notification segment
DIVIDER = rgb("#5c6370")                     # scroll markers

_offset: dict = {}     # os_window_id -> index of the first visible tab (kept across redraws)
_layout: tuple = ()    # (widths, first visible, end) for the pass in progress


def inactive_bg() -> int:
    """Inactive tabs' colour: the first transparent_background_colors entry in kitty.conf (kept
    at @1 so the glyph caps match the body); the plain default background without one."""
    entries = get_options().transparent_background_colors
    return as_rgb(int(entries[0][0])) if entries else DEFAULT


def colors(tab: TabBarData) -> tuple:
    return ACTIVE if tab.is_active else ALERT if tab.needs_attention else (inactive_bg(), INACTIVE_FG)


def title_width(draw_data: DrawData, tab: TabBarData, index: int) -> int:
    scratch = Screen(None, 1, 512)
    draw_title(draw_data, scratch, tab, index, 0)
    return scratch.cursor.x


def compute_layout(draw_data: DrawData, columns: int) -> tuple:
    tm = get_boss().os_window_map.get(draw_data.os_window_id)
    tabs = list(tm.tab_bar_data) if tm is not None else []
    # title + two pads + two caps
    widths = [min(MAX_TAB, max(MIN_TAB, title_width(draw_data, t, i + 1) + 4)) for i, t in enumerate(tabs)]
    active = next((i for i, t in enumerate(tabs) if t.is_active), 0)
    room = columns - 2                         # leave space for the ‹ / › markers
    first = min(_offset.get(draw_data.os_window_id, 0), active)
    while first < active and sum(widths[first:active + 1]) > room:
        first += 1
    end, used = first, 0
    while end < len(widths) and used + widths[end] <= room:
        used += widths[end]
        end += 1
    _offset[draw_data.os_window_id] = first
    return widths, first, max(end, active + 1)


def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData, before: int,
    max_tab_length: int, index: int, is_last: bool, extra_data: ExtraData,
) -> int:
    global _layout
    if index == 1 or not _layout:
        _layout = compute_layout(draw_data, screen.columns)
    widths, first, end = _layout
    i = index - 1
    c = screen.cursor
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
    bg, fg = colors(tab)

    start = c.x
    c.fg, c.bg = bg, DEFAULT
    screen.draw(CAP_L)
    c.fg, c.bg = fg, bg
    c.bold, c.italic = tab.is_active, not tab.is_active
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
