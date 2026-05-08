local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font_with_fallback({
    "PTMono Nerd Font",
    "PT Mono",
})
config.font_size = 10.0
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" } -- disable ligatures
config.line_height = 0.95
config.cell_width = 0.95

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.cursor_thickness = "1.5pt"

-- Scrollback
config.scrollback_lines = 2000

-- Mouse
config.selection_word_boundary = " \t\n{}[]()\"'`,;:│"
config.hide_mouse_cursor_when_typing = true

-- Bell — silence everything
config.audible_bell = "Disabled"
config.visual_bell = {
    fade_in_duration_ms = 0,
    fade_out_duration_ms = 0,
}

-- Window
config.initial_cols = 100
config.initial_rows = 30
config.window_padding = { left = 15, right = 15, top = 15, bottom = 15 }
config.window_decorations = "RESIZE|TITLE"
config.window_close_confirmation = "NeverPrompt"

config.window_background_opacity = 0.8
config.text_background_opacity = 1.0
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.8 } -- ~ kitty inactive_text_alpha 0.8

-- Tabs
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 32
config.show_new_tab_button_in_tab_bar = false

-- Tab title: "{index}: {title} ({num_panes})" — strip user@host prefix the shell sets via OSC
wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
    local pane = tab.active_pane
    local title = pane.title or ""
    title = title:gsub("^[^@%s]+@[^:%s]+:?%s*", "")
    if title == "" and pane.current_working_dir then
        local p = pane.current_working_dir.file_path or ""
        title = p:match("([^/\\]+)[/\\]?$") or p
    end
    local n = tab.panes_by_index and #tab.panes_by_index or 1
    local suffix = (n > 1) and string.format(" (%d)", n) or ""
    return string.format(" %d: %s%s ", tab.tab_index + 1, title, suffix)
end)

config.color_scheme = "OneDark (base16)"

-- Git Bash, login shell so /etc/profile + ~/.bash_profile run before ~/.bashrc.
-- Plain "bash.exe" can resolve to WSL's bash on Windows.
config.default_prog = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login", "-i" }
config.set_environment_variables = {
    CHERE_INVOKING = "1", -- preserve cwd when --login is used
}

-- Hyperlinks
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Performance
config.max_fps = 120
config.front_end = "WebGpu"

-- Keybindings (kitty_mod = CTRL|SHIFT)
config.disable_default_key_bindings = false
config.keys = {
    -- Clipboard
    { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
    { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
    { key = "s", mods = "CTRL|SHIFT", action = act.PasteFrom("PrimarySelection") },

    -- Scrolling
    { key = "UpArrow",   mods = "CTRL|SHIFT", action = act.ScrollByLine(-1) },
    { key = "DownArrow", mods = "CTRL|SHIFT", action = act.ScrollByLine(1) },
    { key = "PageUp",    mods = "CTRL|SHIFT", action = act.ScrollByPage(-1) },
    { key = "PageDown",  mods = "CTRL|SHIFT", action = act.ScrollByPage(1) },
    { key = "Home",      mods = "CTRL|SHIFT", action = act.ScrollToTop },
    { key = "End",       mods = "CTRL|SHIFT", action = act.ScrollToBottom },
    { key = "h",         mods = "CTRL|SHIFT", action = act.ShowDebugOverlay }, -- approximation of show_scrollback

    -- Pane management (kitty "window")
    { key = "Enter", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "n",     mods = "CTRL|SHIFT", action = act.SpawnWindow },
    { key = "w",     mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },
    { key = "]",     mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Next") },
    { key = "[",     mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Prev") },
    { key = "r",     mods = "CTRL|SHIFT", action = act.PaneSelect },

    -- Tabs
    { key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(1) },
    { key = "LeftArrow",  mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },
    { key = "t",          mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "q",          mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
    { key = "PageUp",     mods = "CTRL|SHIFT|ALT", action = act.MoveTabRelative(-1) },
    { key = "PageDown",   mods = "CTRL|SHIFT|ALT", action = act.MoveTabRelative(1) },

    -- Activate pane N (kitty: ctrl+shift+1..9 = first..ninth_window)
    { key = "1", mods = "CTRL|SHIFT", action = act.ActivatePaneByIndex(0) },
    { key = "2", mods = "CTRL|SHIFT", action = act.ActivatePaneByIndex(1) },
    { key = "3", mods = "CTRL|SHIFT", action = act.ActivatePaneByIndex(2) },
    { key = "4", mods = "CTRL|SHIFT", action = act.ActivatePaneByIndex(3) },
    { key = "5", mods = "CTRL|SHIFT", action = act.ActivatePaneByIndex(4) },
    { key = "6", mods = "CTRL|SHIFT", action = act.ActivatePaneByIndex(5) },
    { key = "7", mods = "CTRL|SHIFT", action = act.ActivatePaneByIndex(6) },
    { key = "8", mods = "CTRL|SHIFT", action = act.ActivatePaneByIndex(7) },
    { key = "9", mods = "CTRL|SHIFT", action = act.ActivatePaneByIndex(8) },

    -- Font size
    { key = "=",         mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
    { key = "-",         mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
    { key = "Backspace", mods = "CTRL|SHIFT", action = act.ResetFontSize },

    -- Hints (kitty kitty_mod+e -> open URL)
    { key = "e", mods = "CTRL|SHIFT", action = act.QuickSelect },

    -- Misc
    { key = "F11",    mods = "CTRL|SHIFT", action = act.ToggleFullScreen },
    { key = "F5",     mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
    { key = "Delete", mods = "CTRL|SHIFT", action = act.ClearScrollback("ScrollbackAndViewport") },
}

return config
