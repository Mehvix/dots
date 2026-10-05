set runtimepath^=~/.vim
let &packpath = &runtimepath
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1
if !exists('g:python3_host_prog')
  let s:python3 = expand('~/.venv/bin/python')
  if executable(s:python3)
    let g:python3_host_prog = s:python3
  endif
endif

let s:plug_dir = '~/.vim/plugged'
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
Plug 'nvim-treesitter/nvim-treesitter', { 'branch': 'master', 'do': ':TSUpdate \| TSInstall! lua python javascript typescript c cpp bash diff git_config git_rebase haskell ini latex perl nix' }
Plug 'nvim-treesitter/nvim-treesitter-context'
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
-- Start treesitter highlighting and, when it attaches, turn OFF the legacy
-- regex syntax engine for that buffer. Leaving both on means the buffer is
-- highlighted twice: the colours clash and, worse, the legacy engine does a
-- *synchronous* highlight pass on open that blocks the UI (~160ms on an 8k-line
-- file, far worse on bigger ones). Treesitter parses the visible range only
-- (~1ms), so dropping the regex engine fixes the double-highlight freeze.
--
-- Exceptions (ts_skip_hl): filetypes we deliberately keep on the legacy regex
-- syntax engine instead of treesitter highlighting.
--
-- Force synchronous parsing globally: on nvim 0.11+ parses are time-sliced
-- across frames, so on a big file the module header (which needs the tree
-- parsed all the way up to the enclosing `module` at the top) only appears
-- after several seconds. Sync parsing makes the full tree ready at once — a
-- one-time ~0.4-0.8s cost on opening a large file, in exchange for the header
-- showing immediately.
vim.g._ts_force_sync_parsing = true
local ts_skip_hl = { nix = true }
vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == '' or ts_skip_hl[ft] then return end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) then return end
      if pcall(vim.treesitter.start, args.buf) then
        vim.bo[args.buf].syntax = ''  -- treesitter attached: drop legacy regex syntax
      end
    end)
  end,
})

-- sticky-scroll context headers
if ok_tsctx then
  tsctx.setup({
    max_lines = 4,           -- enclosing scope
    multiline_threshold = 1, -- collapse each context to a single line
    trim_scope = 'outer',
    mode = 'cursor',         -- context dictated by cursor's scope
  })
  local function tsctx_hl()
    local surface = '#1d2029'
    vim.api.nvim_set_hl(0, 'TreesitterContext',           { bg = surface, italic = true })
    vim.api.nvim_set_hl(0, 'TreesitterContextLineNumber', { bg = surface, fg = '#636d83' })
  end
  vim.api.nvim_create_autocmd('ColorScheme', { callback = tsctx_hl })
  tsctx_hl() -- apply now (colorscheme is already set above)
end

function _G.tsctx_go_to_context_end(depth)
  depth = depth or 1
  local line = vim.api.nvim_win_get_cursor(0)[1] -- 1-based
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then return end
  local range = { line - 1, 0, line - 1, 1 }
  parser:parse(range)
  local query = vim.treesitter.query.get(parser:lang(), 'context')
  if not query then return end
  local tree = parser:tree_for_range(range, { ignore_injections = true })
  if not tree then return end

  -- collect enclosing contexts: header starts above the cursor, scope ends at/below it
  local enclosing = {}
  for id, node in query:iter_captures(tree:root(), 0, 0, -1) do
    if query.captures[id] == 'context' then
      local srow, _, erow, ecol = node:range()
      if srow + 1 < line and erow + 1 >= line then
        enclosing[#enclosing + 1] = { srow = srow, erow = erow, ecol = ecol }
      end
    end
  end
  if #enclosing == 0 then return end
  table.sort(enclosing, function(a, b) return a.srow > b.srow end) -- innermost first
  local target = enclosing[math.min(depth, #enclosing)]

  -- a range ending at col 0 means the node stops at the start of the next line,
  -- so the real last content line is the one before it
  local erow = target.erow
  if target.ecol == 0 and erow > 0 then erow = erow - 1 end
  vim.cmd([[normal! m']]) -- record jump so <C-o> comes back
  vim.api.nvim_win_set_cursor(0, { erow + 1, 0 })
end

-- colorpicker (skipped gracefully if the plugin isn't installed on this machine)
local function glibc_ok()
  local out = (vim.fn.systemlist('getconf GNU_LIBC_VERSION')[1] or '')
  local maj, min = out:match('glibc%s+(%d+)%.(%d+)')
  if not maj then return true end -- not glibc (macOS/musl) or unknown -> don't block
  return (tonumber(maj) * 1000 + tonumber(min)) >= 2030
end

local ok_oklch, oklch = pcall(require, "oklch-color-picker")
if ok_oklch and glibc_ok() then
  oklch.setup({
    highlight = {
      virtual_text = "󰝤 ",
      style = "foreground+virtual_left",
      bold = false,
      italic = false,
    }
  })
  vim.keymap.set("n", "<leader>cp", function()
    oklch.pick_under_cursor()
  end, { desc = "Color pick under cursor" })
  vim.keymap.set("n", "<2-LeftMouse>", function()
    oklch.pick_under_cursor()
  end, { desc = "Color pick on double click" })
end

---- folds
--vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
--vim.wo[0][0].foldmethod = 'expr'

-- indent line for all
require("ibl").setup({
  scope = { enabled = false },
  exclude = {
    filetypes = { 'toggleterm' },
    buftypes  = { 'terminal' },
  },
})

-- vary indent for current level
require('mini.indentscope').setup({
  options = {
    try_as_border = true,
    indent_at_cursor = false,
  },
})

-- disable mini.indentscope guides in terminal buffers (e.g. toggleterm)
vim.api.nvim_create_autocmd({ 'TermOpen', 'FileType' }, {
  pattern = { '*' },
  callback = function(args)
    if vim.bo[args.buf].buftype == 'terminal'
        or vim.bo[args.buf].filetype == 'toggleterm' then
      vim.b[args.buf].miniindentscope_disable = true
    end
  end,
})
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#616161", nocombine = true })
  end,
})

-- wilder
local wilder = require('wilder')
-- wilder's vim_search uses :substitute with / as a delimiter, so searching for
-- a literal / (e.g. a path) breaks its completion pipeline. Match directly.
local function search_candidates(_, pattern)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local current = vim.api.nvim_win_get_cursor(0)[1]
  local candidates, seen = {}, {}
  for _, bounds in ipairs({{current, #lines}, {1, current}}) do
    for i = bounds[1], bounds[2] do
      local offset = 0
      while offset <= #lines[i] do
        local ok, result = pcall(vim.fn.matchstrpos, lines[i], pattern, offset)
        if not ok or result[2] == -1 then break end
        local match, start, finish = result[1], result[2], result[3]
        if not seen[match] then
          seen[match] = true
          table.insert(candidates, match)
          if #candidates >= 300 then return candidates end
        end
        offset = math.max(finish, start + 1) -- advance even on empty matches
      end
    end
  end
  return candidates
end
wilder.setup({modes = {':', '/', '?'}})
wilder.set_option('pipeline', {
  wilder.branch(
    wilder.cmdline_pipeline({
      file_command = function(_, arg)
        if string.find(arg, '.', 1, true) ~= nil then
          return {'fd', '-tf', '-H', '-E', '.git', '--', arg}
        else
          return {'fd', '-tf', '-H', '-E', '.git'}
        end
      end,
      dir_command = function(_, arg)
        if string.find(arg, '.', 1, true) ~= nil then
          return {'fd', '-td', '-H', '-E', '.git', '--', arg}
        else
          return {'fd', '-td', '-H', '-E', '.git'}
        end
      end,
    }),
    wilder.vim_search_pipeline({pipeline = {
      wilder.vim_substring_pattern(),
      search_candidates,
      wilder.result_output_escape('^$*~[]/\\'),
    }})
  ),
})
local fg, sel_bg = '#ABB2BF', '#3E4452'
vim.api.nvim_set_hl(0, 'WilderNormal',         { fg = fg,        bg = 'NONE' })
vim.api.nvim_set_hl(0, 'WilderSelected',       { fg = fg,        bg = sel_bg, bold = true })
vim.api.nvim_set_hl(0, 'WilderAccent',         { fg = '#E5C07B', bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'WilderSelectedAccent', { fg = '#E5C07B', bg = sel_bg, bold = true })
vim.api.nvim_set_hl(0, 'WilderBorder',         { fg = fg,        bg = 'NONE' })
wilder.set_option('renderer', wilder.popupmenu_renderer(
  wilder.popupmenu_border_theme({
    pumblend = 0,
    highlighter = wilder.basic_highlighter(),
    left  = {' ', wilder.popupmenu_devicons()},
    right = {' ', wilder.popupmenu_scrollbar()},
    highlights = {
      border          = 'WilderBorder',
      default         = 'WilderNormal',
      selected        = 'WilderSelected',
      accent          = 'WilderAccent',
      selected_accent = 'WilderSelectedAccent',
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

-- Store oldfiles relative to the roots named in $PATH_ABBREV_VARS (colon-
-- separated var names, set per-site, see .profile _hist_rewrite_abbrev): a path
-- under a root is folded to a literal "$NAME/..." token on save, and expanded
-- back to the *current* $NAME on read. This makes the recent-files list
-- portable across checkouts (a file remembered in one checkout opens in
-- another). Longest root wins for nested roots. Note: nvim does NOT auto-expand
-- $VAR in paths (filereadable/:edit see the literal), so we keep the in-memory
-- list absolute and only write tokens to ShaDa. $HOME is always an implicit
-- root, folded to "~/..." (same as the shell history rewrite).
local function abbrev_roots()        -- { {name, value}, ... } longest value first
  local roots = {}
  for name in (vim.env.PATH_ABBREV_VARS or ''):gmatch('[^:]+') do
    local v = name:match('^[%a_][%w_]*$') and vim.env[name]
    if v then v = v:gsub('/$', '') end
    if v and v:match('^/.') then roots[#roots + 1] = { name, v } end
  end
  local home = (vim.env.HOME or ''):gsub('/$', '')
  if home:match('^/.') then roots[#roots + 1] = { '~', home } end
  table.sort(roots, function(a, b) return #a[2] > #b[2] end)
  return roots
end
local function path_abbrev(path, roots)   -- absolute -> "$NAME/..." / "~/..." (save side)
  for _, r in ipairs(roots) do
    local name, root = r[1], r[2]
    local tok = name == '~' and '~' or '$' .. name
    if path == root then return tok end
    if path:sub(1, #root + 1) == root .. '/' then return tok .. path:sub(#root + 1) end
  end
  return path
end
local function path_expand(path)     -- "$NAME/..." / "~/..." -> absolute (read side)
  if path == '~' or path:sub(1, 2) == '~/' then
    local home = vim.env.HOME
    return (home and home ~= '') and (home:gsub('/$', '') .. path:sub(2)) or path
  end
  -- any $NAME token, not just listed ones: entries survive list edits, and an
  -- unset var leaves the literal, which oldfile_is_junk drops as unreadable
  local name, rest = path:match('^%$([%a_][%w_]*)(.*)$')
  if not name or (rest ~= '' and rest:sub(1, 1) ~= '/') then return path end
  local v = vim.env[name]
  return (v and v ~= '') and (v:gsub('/$', '') .. rest) or path
end

-- Junk is that which is unreadable + manually spec'd:
local function oldfile_is_junk(file)
  return file:match("%[Wilder")
    or file:match("^/tmp/")
    or file:match("^/var/tmp/")
    or file:match("/%.git/")
    or vim.fn.filereadable(file) == 0
end

-- junk-free telescope old-files
local function telescope_oldfiles()
  local seen, cleaned = {}, {}
  for _, f in ipairs(vim.v.oldfiles) do
    f = path_expand(f)
    if not seen[f] and not oldfile_is_junk(f) then
      seen[f] = true
      cleaned[#cleaned + 1] = f
    end
  end
  vim.v.oldfiles = cleaned
  require('telescope.builtin').oldfiles()
end

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
  -- clear search highlight
  { 'n', '<Esc>',       '<cmd>nohlsearch<cr>' },
  -- git hunks
  { 'n', '<A-k>',       '<cmd>GitGutterPrevHunk<cr>' },                  -- alt+k, jump to next git hunk
  { 'n', '<A-j>',       '<cmd>GitGutterNextHunk<cr>' },                  -- alt+j, jump to next git hunk
  -- treesitter context
  { 'n', '[c',          function() require('treesitter-context').go_to_context(vim.v.count1) end }, -- jump to enclosing context header
  { 'n', ']c',          function() _G.tsctx_go_to_context_end(vim.v.count1) end },                  -- jump to enclosing context end/tail
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
  { 'n', '<C-e>',       function() telescope_oldfiles() end },
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
  -- These mapped keys bypass Vim's :s abbreviation in .vimrc.
  if cmd == 's' and pos == 2 then
    return '\b%s' .. fallback_char
  end
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

-- Clean up oldfiles before saving ShaDa: drop junk, then fold paths under $PATH_ABBREV_VARS
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local out, roots = {}, abbrev_roots()
    for _, f in ipairs(vim.v.oldfiles) do
      f = path_expand(f)
      if not oldfile_is_junk(f) then out[#out + 1] = path_abbrev(f, roots) end
    end
    vim.v.oldfiles = out
  end,
})
EOF


source ~/.vimrc
