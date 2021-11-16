" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" Set shell to zsh
set shell=/usr/bin/zsh

" Yank copies to system clipoard (needs xsel)
set clipboard=unnamedplus

" For colemak-dh
""noremap h k
""noremap j h
""noremap k j

" Wrap around in insert mode -- vim.fandom.com/wiki/Automatically_wrap_left_and_right
set whichwrap+=<,>,h,l,[,]

" Enter command mode easier
nnoremap ; :

" Move line
nnoremap <S-Up>   :<C-u>silent! move-2<CR>==
nnoremap <S-Down> :<C-u>silent! move+<CR>==
xnoremap <S-Up>   :<C-u>silent! '<,'>move-2<CR>gv=gv
xnoremap <S-Down> :<C-u>silent! '<,'>move'>+<CR>gv=gv

" Misc
set noerrorbells    " Gets rid of beeping sound
set autowrite       " Auto-save before commands like :next and :make
set backspace=indent,eol,start  " Allow backspacing over everything in insert mode
set history=1000    " Keep x lines of command line history
set encoding=utf-8

" Syntax HL
syntax on           " Syntax highlighting
filetype plugin indent on
au BufRead,BufNewFile .aliases          set syn=bash
au BufRead,BufNewFile *ssh/config*,*sshd*   set syn=sshconfig
au BufRead,BufNewFile .prettier*        set syn=json
au BufRead,BufNewFile .gitattributes    set syn=json

" Information
set showcmd         " Show (partial) command in status line
""set showmode        " Show the current mode
set laststatus=2    " Always show status line
set statusline=%.40F%=%m\ %Y\ Line:\ %3l/%L[%3p%%]
""set ruler
set shortmess=I     " Don't show the startup message

" Navigation
set nu              " Set line numbering
""set relativenumber  " Show relative line numbers
set scrolloff=5     " Keep at least 5 lines above/below cursor
set mouse=a         " Enable mouse usage in all modes
set mousehide       " Hide the mouse when typing

" Tabs
set tabstop=4       " Each tab is 4 spaces
set shiftwidth=4    " Sets >> and << width
set expandtab       " Uses spaces instead of tabs
set autoindent      " Continue indent when pasting
set smartindent     " Reacts to the synthax of the code
set smarttab        " Automatically indent newlines

" Searching
set ignorecase      " Do case insensitive matching
set smartcase       " Do smart case matching
set incsearch       " Incremental search
set hlsearch        " highlight searches
set showmatch       " Show matching brackets.
autocmd VimEnter * nnoremap <esc> :nohlsearch<return><esc>    " Clear highlight on pressing esc
autocmd InsertEnter * :let @/=""    " Clear highlight when entering insert mode

" Turn on persistent undo
if has('persistent_undo')
    set undodir=~/.vim/undo//
    set undofile
    set undolevels=1000
    set undoreload=10000
endif

" Use backups -- http://stackoverflow.com/a/15317146
set backup
set writebackup
set backupdir=~/.vim/backup//

" Use a specified swap folder
" Source:   http://stackoverflow.com/a/15317146
set directory=~/.vim/swap//

if has('nvim') 
    " Neovim Specific Settings
    tnoremap <Esc> <C-\><C-n>
else
    " Standard vim specific commands (deprecated in nvim)
    set ttymouse=xterm2
endif

