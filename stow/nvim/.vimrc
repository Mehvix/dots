" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" Set shell to zsh
set shell=/usr/bin/zsh

" Yank copies to system clipoard (needs xsel)
set clipboard=unnamedplus

" Colorscheme / Theme
let g:onedark_terminal_italics=1

" One Theme
if has('autocmd') && !has('gui_running')
    augroup colorset
        autocmd!
        autocmd ColorScheme one silent!
                    \ call one#highlight('Normal', '', 'none', '')
    augroup END
endif

" onedark.vim
if (has("autocmd") && !has("gui_running"))
    augroup colorset
        autocmd!
        let s:white = { "gui": "#ABB2BF", "cterm": "145", "cterm16" : "7" }
        autocmd ColorScheme * call onedark#set_highlight("Normal", { "fg": s:white }) " `bg` will not be styled since there is no `bg` setting
    augroup END
endif

let g:onedark_color_overrides = {
\ "comment_grey": {"gui": "#767676", "cterm": "243", "cterm16": "2" },
\ "gutter_fg_grey": {"gui": "#767676", "cterm": "243", "cterm16": "2" },
\}

" Extensions
" Lightline
if !has('gui_running')
    set t_Co=256
endif

set noshowmode      " Remove mode
let g:airline_theme='one'
let g:lightline = {
            \ 'colorscheme': 'onedark',
            \ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
		    \ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" },
            \ }

colorscheme onedark
set background=dark 

" Airline
" let g:airline_powerline_fonts = 1
" let g:airline_theme='onedark'


" For colemak-dh
noremap h k
noremap j h
noremap k j

" Enter command mode easier
nnoremap ; :

" Move line
nnoremap <S-Up>   :<C-u>silent! move-2<CR>==
nnoremap <S-Down> :<C-u>silent! move+<CR>==
xnoremap <S-Up>   :<C-u>silent! '<,'>move-2<CR>gv=gv
xnoremap <S-Down> :<C-u>silent! '<,'>move'>+<CR>gv=gv

" Refreshes screen
""nnoremap <Enter>    :nohl<CR><C-l><Enter>

" Wrap beginning of next / end of previous
:set whichwrap+=>,l
:set whichwrap+=<,h

" Misc
syntax on           " Syntax highlighting
set noerrorbells    " Gets rid of beeping sound
set autowrite       " Auto-save before commands like :next and :make
set backspace=indent,eol,start  " Allow backspacing over everything in insert mode
set history=500     " Keep x lines of command line history

" Information
set showcmd         " Show (partial) command in status line
" set showmode        " Show the current mode
set laststatus=2    " Always show status line
set statusline=%.40F%=%m\ %Y\ Line:\ %3l/%L[%3p%%]

" Navigation
set nu              " Set line numbering
" set relativenumber  " Show relative line numbers
set scrolloff=5     " Keep at least 5 lines above/below cursor
set mouse=a         " Enable mouse usage in all modes
set mousehide       " Hide the mouse when typing

" Tabs
set expandtab       " Uses spaces instead of tabs
set tabstop=4       " Each tab is 4 spaces
set shiftwidth=4    " Sets the >> and << width
set autoindent
set shiftwidth=4    " Sets >> and << width

" Searching
set ignorecase      " Do case insensitive matching
set smartcase       " Do smart case matching
set incsearch       " Incremental search
set hlsearch        " highlight searches
set showmatch       " Show matching brackets.

if has('nvim') 
    " Neovim Specific Settings
    tnoremap <Esc> <C-\><C-n>
else
    " Standard vim specific commands (deprecated in nvim)
    set ttymouse=xterm2
endif


