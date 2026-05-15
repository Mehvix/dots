set runtimepath^=~/.vim
let &packpath = &runtimepath
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1
let s:python3 = expand('~/.venv/bin/python')
if filereadable(s:python3)
  let g:python3_host_prog = s:python3
endif

" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

Plug 'fladson/vim-kitty',   { 'for': 'kitty' }
Plug 'lervag/vimtex',       { 'for': 'tex' }
Plug 'kylelaker/riscv.vim', { 'for': 'asm' }

Plug 'itchyny/lightline.vim'
Plug 'joshdick/onedark.vim'
Plug 'edkolev/tmuxline.vim'
Plug 'airblade/vim-gitgutter'
Plug 'lambdalisue/nerdfont.vim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-tree/nvim-tree.lua'
Plug 'akinsho/toggleterm.nvim', {'tag' : '*'}

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
vim.cmd('colorscheme onedark')
vim.o.background = 'dark'

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

-- binds
local map = vim.keymap.set
for _, m in ipairs({
  -- commentary
  { 'n', '<C-/>',      '<cmd>Commentary<cr>' },
  { 'v', '<C-/>',      ':Commentary<cr>' },
  { 'n', '<C-_>',      '<cmd>Commentary<cr>' },
  { 'v', '<C-_>',      ':Commentary<cr>' },
  -- file tree
  { 'n', '<C-b>',      '<cmd>NvimTreeFindFileToggle<cr>' },
  -- terminal
  { 'n', '<C-\\>',      '<cmd>ToggleTerm<cr>' },
  { 'n', '<C-S-\\>',    '<cmd>ToggleTerm direction="float"<cr>' },
  { 't', '<C-\\>',      '<cmd>ToggleTerm<cr>' },
  { 't', '<C-S-\\>',    '<cmd>ToggleTerm<cr>' },
  -- buffers
  { 'n', '<C-h>',      '<cmd>bp<cr>' },
  { 'n', '<C-l>',      '<cmd>bn<cr>' },
  -- git hunks
  { 'n', '<A-k>',      '<cmd>GitGutterPrevHunk<cr>' },
  { 'n', '<A-j>',      '<cmd>GitGutterNextHunk<cr>' },
  -- char search repeat (defined in .vimrc)
  { 'n', '<Space>',    '<cmd>call RepeatCharSearch(0)<cr>' },
  { 'n', ',',          '<cmd>call RepeatCharSearch(1)<cr>' },
  { 'x', '<Space>',    '<cmd>call RepeatCharSearch(0)<cr>' },
  { 'x', ',',          '<cmd>call RepeatCharSearch(1)<cr>' },
  { 'o', '<Space>',    '<cmd>call RepeatCharSearch(0)<cr>' },
  { 'o', ',',          '<cmd>call RepeatCharSearch(1)<cr>' },
}) do
  map(m[1], m[2], m[3], { silent = true })
end

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
      file_command = {'fd', '-tf'},
      dir_command = {'fd', '-td'},
      -- use {'cpsm_filter'} for performance, requires cpsm vim plugin
      -- found at https://github.com/nixprime/cpsm
      filters = {'fuzzy_filter', 'difflib_sorter'},
    }),
    wilder.cmdline_pipeline(),
    wilder.python_search_pipeline()
  ),
})
wilder.set_option('renderer', wilder.wildmenu_renderer(
  -- use wilder.wildmenu_lightline_theme() if using Lightline
  wilder.wildmenu_airline_theme({
    -- highlights can be overriden, see :h wilder#wildmenu_renderer()
    highlights = {default = 'StatusLine'},
    highlighter = wilder.basic_highlighter(),
    separator = ' · ',
  })
))
wilder.set_option('renderer', wilder.popupmenu_renderer({
  -- highlighter applies highlighting to the candidates
  highlighter = wilder.basic_highlighter(),
}))
wilder.set_option('renderer', wilder.popupmenu_renderer({
  highlighter = wilder.basic_highlighter(),
  left = {' ', wilder.popupmenu_devicons()},
  right = {' ', wilder.popupmenu_scrollbar()},
}))


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
    dotfiles = true,
  },
}

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
EOF



source ~/.vimrc
