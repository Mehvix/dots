set runtimepath^=~/.vim
let &packpath = &runtimepath
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1
let s:python3 = expand('~/.venv/bin/python')
if filereadable(s:python3)
  let g:python3_host_prog = s:python3
endif

let s:host = substitute(hostname(), '\..*', '', '')
if s:host ==# 'etx-maxv'
  let s:plug_dir = '/var/tmp/' . $USER . '/nvim/plugged'
  if !isdirectory(s:plug_dir) | call mkdir(s:plug_dir, 'p') | endif
else
  let s:plug_dir = '~/.vim/plugged'
endif
call plug#begin(s:plug_dir)

Plug 'fladson/vim-kitty',   { 'for': 'kitty' }
Plug 'lervag/vimtex',       { 'for': 'tex' }
Plug 'kylelaker/riscv.vim', { 'for': 'asm' }

Plug 'itchyny/lightline.vim'
Plug 'joshdick/onedark.vim'
Plug 'edkolev/tmuxline.vim'
Plug 'airblade/vim-gitgutter'
Plug 'lambdalisue/nerdfont.vim'
Plug 'nvim-tree/nvim-web-devicons'

Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
Plug 'nvim-tree/nvim-tree.lua'
Plug 'akinsho/toggleterm.nvim', {'tag' : '*'}
Plug 'eero-lehtinen/oklch-color-picker.nvim'

Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
" Plug 'chaoren/vim-wordmotion'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'echasnovski/mini.indentscope'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate \| TSInstall! lua python javascript typescript c cpp bash diff git_config git_rebase haskell ini latex perl nix' }
Plug 'stevearc/conform.nvim'
" Plug 'godlygeek/tabular'

if has('nvim')
  function! UpdateRemotePlugins(...)
    " Needed to refresh runtime files
    let &rtp=&rtp
    UpdateRemotePlugins
  endfunction
  Plug 'gelguy/wilder.nvim', { 'do': function('UpdateRemotePlugins') }
else
  Plug 'gelguy/wilder.nvim'
  " To use Python remote plugin features in Vim, can be skipped
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

call plug#end() " init plugin system

lua << EOF
vim.opt.termguicolors = true

-- colorscheme (onedark)
vim.g.onedark_terminal_italics = 1
vim.g.onedark_color_overrides = {
  comment_grey   = { gui = '#8a8a8a', cterm = '245', cterm16 = '2' },
  gutter_fg_grey = { gui = '#8a8a8a', cterm = '245', cterm16 = '2' },
}
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = 'onedark',
  callback = function()
    vim.fn['onedark#set_highlight']('Normal', { fg = { gui = '#ABB2BF', cterm = '145', cterm16 = '7' } })
  end,
})
vim.o.background = 'dark'
vim.cmd('colorscheme onedark')

-- lightline
vim.o.showmode = false
vim.g.lightline = {
  colorscheme = 'onedark',
  separator    = { left = '\u{e0b0}', right = '\u{e0b2}' },
  subseparator = { left = '\u{e0b1}', right = '\u{e0b3}' },
}

-- gitgutter
vim.g.gitgutter_sign_added = '+'
vim.g.gitgutter_sign_modified = '>'
vim.g.gitgutter_sign_removed = '-'
vim.g.gitgutter_sign_removed_first_line = '^'
vim.g.gitgutter_sign_modified_removed = '<'

-- formatting with conform
require("conform").setup({
  formatters_by_ft = {
    nix = { "alejandra" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})

-- tree-sitter + indent-blankline
vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == 'nix' or ft == '' then return end
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- colorpicker
require("oklch-color-picker").setup({
  highlight = {
    virtual_text = "󰝤 ",
    style = "foreground+virtual_left",
    bold = false,
    italic = false,
  }
})
vim.keymap.set("n", "<leader>cp", function()
  require("oklch-color-picker").pick_under_cursor()
end, { desc = "Color pick under cursor" })
vim.keymap.set("n", "<2-LeftMouse>", function()
  require("oklch-color-picker").pick_under_cursor()
end, { desc = "Color pick on double click" })

---- folds
--vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
--vim.wo[0][0].foldmethod = 'expr'

-- indent line for all
require("ibl").setup({
  scope = { enabled = false }
})

-- vary indent for current level
require('mini.indentscope').setup({
  options = {
    try_as_border = true,
    indent_at_cursor = false,
  },
})
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#616161", nocombine = true })
  end,
})

-- wilder
local wilder = require('wilder')
wilder.setup({modes = {':', '/', '?'}})
wilder.set_option('pipeline', {
  wilder.branch(
    wilder.python_file_finder_pipeline({
      file_command = {'fd', '-tf', '-H', '-E', '.git'},
      dir_command = {'fd', '-td', '-H', '-E', '.git'},
      -- use {'cpsm_filter'} for performance, requires cpsm vim plugin
      -- found at https://github.com/nixprime/cpsm
      filters = {'fuzzy_filter', 'difflib_sorter'},
    }),
    wilder.cmdline_pipeline(),
    wilder.python_search_pipeline()
  ),
})
local accent = {{a = 1}, {foreground = '180', bold = true}, {foreground = '#E5C07B', bold = true}}
-- menu bg: black #282C34/235, cursor_grey #2C323C/236, visual_grey #3E4452/237
local fg, bg, sel_bg = '#ABB2BF', '#282C34', '#3E4452'
local normal   = {{a = 1}, {foreground = '145', background = '235'}, {foreground = fg, background = bg}}
local selected = {{a = 1}, {foreground = '145', background = '237'}, {foreground = fg, background = sel_bg, bold = true}}
wilder.set_option('renderer', wilder.popupmenu_renderer(
  wilder.popupmenu_border_theme({
    pumblend = 40,
    highlighter = wilder.basic_highlighter(),
    left  = {' ', wilder.popupmenu_devicons()},
    right = {' ', wilder.popupmenu_scrollbar()},
    highlights = {
      border          = 'FloatBorder',
      default         = wilder.make_hl('WilderNormal',         'Pmenu',    normal),
      selected        = wilder.make_hl('WilderSelected',       'PmenuSel', selected),
      accent          = wilder.make_hl('WilderAccent',         'Pmenu',    accent),
      selected_accent = wilder.make_hl('WilderSelectedAccent', 'PmenuSel', accent),
    },
    border = 'double',
  })
))

-- toggleterm
require("toggleterm").setup{
  shade_terminals = false
}

-- nvim-tree
require("nvim-tree").setup{
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = false,
    git_ignored = false,
    custom = { '^.git$' },
  },
}

require('telescope').setup {
  defaults = {
    borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
  },
  pickers = {
    oldfiles = {
      cwd_only = false,
    },
    find_files = {
      find_command = { 'fd', '-tf', '--hidden', '--ignore-file',
        vim.fn.stdpath('config') .. '/fd-ignore' },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  }
}
require('telescope').load_extension('fzf')

-- brighten dim telescope counter (x/y/z) and fuzzy-match chars
local function telescope_hl()
  vim.api.nvim_set_hl(0, 'TelescopePromptCounter', { fg = '#ABB2BF' })       -- was NonText (dim)
  vim.api.nvim_set_hl(0, 'TelescopeMatching',      { fg = '#56B6C2', bold = true })
end
vim.api.nvim_create_autocmd('ColorScheme', { callback = telescope_hl })
telescope_hl()

-- clipboard
local over_ssh = os.getenv('SSH_TTY') ~= nil
if over_ssh then
  vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
      if vim.v.event.operator == 'y' then
        require('vim.ui.clipboard.osc52').copy('+')(vim.v.event.regcontents)
      end
    end,
  })
else
  local osc52 = require('vim.ui.clipboard.osc52')
  vim.g.clipboard = {
    name = 'osc52',
    copy  = { ['+'] = osc52.copy('+'),  ['*'] = osc52.copy('*')  },
    paste = { ['+'] = osc52.paste('+'), ['*'] = osc52.paste('*') },
  }
  vim.opt.clipboard = 'unnamedplus'
end

-- vscode incompat w latest v12 CSI u keeb protocol
if vim.env.TERM_PROGRAM == 'vscode' then
  vim.schedule(function()
    io.stdout:write('\x1b[>0u')    -- disable CSI u (kitty keyboard protocol)
    io.stdout:write('\x1b[>4;0m')  -- disable modifyOtherKeys
    io.stdout:flush()
  end)
end

-- binds
local map = vim.keymap.set
for _, m in ipairs({
  -- commentary
  { 'n', '<C-/>',       '<cmd>Commentary<cr>' },
  { 'v', '<C-/>',       ':Commentary<cr>' },
  { 'n', '<C-_>',       '<cmd>Commentary<cr>' },                         -- ctrl+/ fallback for some terminals
  { 'v', '<C-_>',       ':Commentary<cr>' },
  -- file tree
  { 'n', '<C-b>',       '<cmd>NvimTreeFindFileToggle<cr>' },
  -- terminal
  { 'n', '<C-\\>',      '<cmd>ToggleTerm<cr>' },
  { 'n', '<C-S-\\>',    '<cmd>ToggleTerm direction="float"<cr>' },      -- ctrl+shift+\
  { 'n', '<C-j>',       '<cmd>ToggleTerm<cr>' },
  { 't', '<C-\\>',      '<cmd>ToggleTerm<cr>' },
  { 't', '<C-S-\\>',    '<cmd>ToggleTerm<cr>' },
  { 't', '<C-j>',       '<cmd>ToggleTerm<cr>' },
  -- buffers
  { 'n', '<C-h>',       '<cmd>bp<cr>' },
  { 'n', '<C-l>',       '<cmd>bn<cr>' },
  -- git hunks
  { 'n', '<A-k>',       '<cmd>GitGutterPrevHunk<cr>' },                  -- alt+k
  { 'n', '<A-j>',       '<cmd>GitGutterNextHunk<cr>' },                  -- alt+j
  -- char search repeat (defined in .vimrc)
  { 'n', '<Space>',     '<cmd>call RepeatCharSearch(0)<cr>' },
  { 'n', ',',           '<cmd>call RepeatCharSearch(1)<cr>' },
  { 'x', '<Space>',     '<cmd>call RepeatCharSearch(0)<cr>' },
  { 'x', ',',           '<cmd>call RepeatCharSearch(1)<cr>' },
  { 'o', '<Space>',     '<cmd>call RepeatCharSearch(0)<cr>' },
  { 'o', ',',           '<cmd>call RepeatCharSearch(1)<cr>' },
  -- telescope
  { 'n', '<C-p>',       '<cmd>Telescope find_files<cr>' },
  { 'n', '<C-f>',       '<cmd>Telescope live_grep<cr>' },
  { 'n', '<C-e>',       '<cmd>Telescope oldfiles<cr>' },
  { 'n', '<C-S-f>',     '<cmd>Telescope grep_string<cr>' },              -- ctrl+shift+f
  { 'n', '<A-b>',       '<cmd>Telescope buffers<cr>' },                  -- alt+b
  { 'n', '<A-h>',       '<cmd>Telescope help_tags<cr>' },                -- alt+h
  { 'n', '<A-g>',       '<cmd>Telescope git_status<cr>' },               -- alt+g
}) do
  map(m[1], m[2], m[3], { silent = true })
end

-- Automatically expand `.` to the directory of the current file in the command-line
-- when typing `:e .` followed by `/` or `<Space>`.
local function expand_dot_to_current_dir(fallback_char)
  if vim.fn.getcmdtype() ~= ':' then
    return fallback_char
  end
  local cmd = vim.fn.getcmdline()
  local pos = vim.fn.getcmdpos()
  local char_before = cmd:sub(pos - 1, pos - 1)
  if char_before == '.' then
    local first_word = cmd:match("^%s*(%a+)")
    local file_cmds = {
      e = true, edit = true, w = true, write = true, saveas = true,
      vs = true, vsplit = true, vsp = true, sp = true, split = true,
      tabe = true, tabedit = true, find = true
    }
    if first_word and file_cmds[first_word] then
      local pattern = "^%s*" .. first_word .. "!?%s+%.$"
      if cmd:sub(1, pos - 1):match(pattern) then
        return "\b" .. vim.fn.expand('%:p:h') .. "/"
      end
    end
  end
  return fallback_char
end

vim.keymap.set('c', '/', function() return expand_dot_to_current_dir('/') end, { expr = true })
vim.keymap.set('c', '<Space>', function() return expand_dot_to_current_dir(' ') end, { expr = true })

-- Clean up oldfiles before saving ShaDa to prevent pollution from temporary
-- buffers (like wilder.nvim float windows) and deleted files.
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    vim.v.oldfiles = vim.tbl_filter(function(file)
      -- Exclude wilder float buffers, temporary directories, and unreadable/deleted files
      if file:match("%[Wilder") then return false end
      if file:match("^/tmp/") then return false end
      if file:match("^/var/tmp/") then return false end
      if vim.fn.filereadable(file) == 0 then return false end
      return true
    end, vim.v.oldfiles)
  end,
})
EOF


source ~/.vimrc
