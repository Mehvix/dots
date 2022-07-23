" use vim settings, rather than vi settings (much better!).
" this must be first, because it changes other options as a side effect.
set nocompatible

" set shell to zsh
set shell=/usr/bin/zsh

" yank copies to system clipoard (needs xsel)
set clipboard=unnamedplus

" for colemak-dh
""noremap h k
""noremap j h
""noremap k j

" wrap around in insert mode -- vim.fandom.com/wiki/Automatically_wrap_left_and_right
set whichwrap+=<,>,h,l,[,]

" enter command mode easier
nnoremap ; :

" move line
nnoremap <A-Up>   :<C-u>silent! move-2<CR>==
nnoremap <A-Down> :<C-u>silent! move+<CR>==
xnoremap <A-Up>   :<C-u>silent! '<,'>move-2<CR>gv=gv
xnoremap <A-Down> :<C-u>silent! '<,'>move'>+<CR>gv=gv

" misc
set noerrorbells    " gets rid of beeping sound
set autowrite       " auto-save before commands like :next and :make
set backspace=indent,eol,start  " allow backspacing over everything in insert mode
set history=1000    " keep x lines of command line history
set encoding=utf-8

" syntax HL
syntax on           " syntax highlighting
filetype plugin indent on
au BufRead,BufNewFile .aliases          set syn=bash
au BufRead,BufNewFile  */yapf/*         set syn=bash
au BufRead,BufNewFile *ssh/config*,*sshd*   set syn=sshconfig
au BufRead,BufNewFile .prettier*        set syn=json
au BufRead,BufNewFile .gitattributes    set syn=json
au BufRead,BufNewFile *.conf            set syn=conf

" information
set showcmd         " show (partial) command in status line
""set showmode        " show the current mode
set laststatus=2    " always show status line
set statusline=%.40F%=%m\ %Y\ Line:\ %3l/%L[%3p%%]
set cmdheight=1

""set ruler
set shortmess=aI     " don't show the startup message and hide 'Hit ENTER to continue'

" navigation
set nu              " set line numbering
""set relativenumber  " show relative line numbers
set scrolloff=5     " keep at least 5 lines above/below cursor
set mouse=a         " enable mouse usage in all modes
set mousehide       " hide the mouse when typing

" tabs
set tabstop=4       " each tab is 4 spaces
set shiftwidth=4    " sets >> and << width
set expandtab       " uses spaces instead of tabs
set autoindent      " continue indent when pasting
set smartindent     " reacts to the synthax of the code
set smarttab        " automatically indent newlines

" searching
set ignorecase      " do case insensitive matching
set smartcase       " do smart case matching
set incsearch       " incremental search
set hlsearch        " highlight searches
set showmatch       " show matching brackets.
"autocmd VimEnter * nnoremap <esc> :nohlsearch<return><esc>    " clear highlight on pressing esc
autocmd InsertEnter * :let @/=""    " clear highlight when entering insert mode

" turn on persistent undo
if has('persistent_undo')
    set undodir=~/.vim/undo//
    set undofile
    set undolevels=1000
    set undoreload=10000
endif

" use backups -- http://stackoverflow.com/a/15317146
set backup
set writebackup
set backupdir=~/.vim/backup//

" use a specified swap folder
" src:   http://stackoverflow.com/a/15317146
set directory=~/.vim/swap//

if has('nvim') 
    " neovim specific settings
    tnoremap <Esc> <C-\><C-n>
else
    " standard vim specific commands (deprecated in nvim)
    set ttymouse=xterm2
endif

