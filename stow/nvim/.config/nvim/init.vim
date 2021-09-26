set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath


" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin(has('nvim') ? stdpath('data') . '/plugged' : '~/.vim/plugged')

" Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
Plug 'itchyny/lightline.vim'
Plug 'rakr/vim-one'
Plug 'joshdick/onedark.vim'

" Initialize plugin system
call plug#end()

source ~/.vimrc     " Load vim settings
