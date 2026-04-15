set runtimepath^=~/.vim
let &packpath = &runtimepath

" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'itchyny/lightline.vim'
Plug 'joshdick/onedark.vim'
Plug 'edkolev/tmuxline.vim'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'echasnovski/mini.indentscope'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate \| TSInstall! lua python javascript typescript c cpp bash diff git_config git_rebase haskell ini latex perl nix' }
Plug 'stevearc/conform.nvim'
Plug 'fladson/vim-kitty'
"Plug 'lervag/vimtex'
Plug 'kylelaker/riscv.vim'

call plug#end() " init plugin system

if !has('gui_running')
    set t_Co=256
endif

" formatting with conform
lua << EOF
require("conform").setup({
  formatters_by_ft = {
    nix = { "alejandra" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})
EOF

" tree-sitter + indent-blankline
lua << EOF
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
EOF

" onedark.vim
if (has("autocmd") && !has("gui_running"))
    augroup colorset
        autocmd!
        let s:white = { "gui": "#ABB2BF", "cterm": "145", "cterm16" : "7" }
        autocmd ColorScheme * call onedark#set_highlight("Normal", { "fg": s:white }) " `bg` will not be styled since there is no `bg` setting
    augroup END
endif
let g:onedark_terminal_italics=1
let g:onedark_color_overrides = {
\ "comment_grey": {"gui": "#767676", "cterm": "243", "cterm16": "2" },
\ "gutter_fg_grey": {"gui": "#767676", "cterm": "243", "cterm16": "2" },
\}

colorscheme onedark
set background=dark

" lightline
set noshowmode      " rm mode, redundant w lightline
let g:lightline = {
\ 'colorscheme': 'onedark',
\ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
\ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" },
\ }

" fontawesome icons as signs
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '>'
let g:gitgutter_sign_removed = '-'
let g:gitgutter_sign_removed_first_line = '^'
let g:gitgutter_sign_modified_removed = '<'

" comment toggle with ctrl + /
nmap <C-/> :Commentary<CR>
vmap <C-/> :Commentary<CR>
nmap <C-_> :Commentary<CR>
vmap <C-_> :Commentary<CR>

lua << EOF
local osc52 = require('vim.ui.clipboard.osc52')
local dumb_term = os.getenv('SSH_TTY') and not os.getenv('KITTY_PID') and not os.getenv('TERM_PROGRAM')

if dumb_term then
  -- OSC 52 copy-only; paste works normally within vim
  vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
      if vim.v.event.operator == 'y' then
        osc52.copy('+')(vim.v.event.regcontents)
      end
    end,
  })
  -- flush garbled DA response that arrives late over SSH
  vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
      vim.defer_fn(function()
        local ok, c = pcall(vim.fn.getchar, 0)
        while ok and c ~= 0 do ok, c = pcall(vim.fn.getchar, 0) end
        vim.cmd('stopinsert | echo ""')
      end, 150)
    end,
  })
else
  vim.g.clipboard = {
    name = 'osc52',
    copy  = { ['+'] = osc52.copy('+'),  ['*'] = osc52.copy('*')  },
    paste = { ['+'] = osc52.paste('+'), ['*'] = osc52.paste('*') },
  }
  vim.opt.clipboard = 'unnamedplus'
end
EOF

" vscode incompat w latest v12 CSI u keeb protocol (?)
lua << EOF
if vim.env.TERM_PROGRAM == 'vscode' then
  vim.schedule(function()
    io.stdout:write('\x1b[>0u')    -- disable CSI u (kitty keyboard protocol)
    io.stdout:write('\x1b[>4;0m')  -- disable modifyOtherKeys
    io.stdout:flush()
  end)
end
EOF

source ~/.vimrc " vim settings
