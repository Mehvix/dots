set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin(has('nvim') ? stdpath('data') . '/plugged' : '~/.vim/plugged')

" Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
Plug 'airblade/vim-gitgutter'
Plug 'itchyny/lightline.vim'
Plug 'rakr/vim-one'
Plug 'joshdick/onedark.vim'
Plug 'edkolev/tmuxline.vim'
Plug 'fladson/vim-kitty'
Plug 'tpope/vim-fugitive'
Plug 'lervag/vimtex'
Plug 'numToStr/Comment.nvim'

" Initialize plugin system
call plug#end()

lua require('Comment').setup()

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
""let g:airline_powerline_fonts = 1
""let g:airline_theme='onedark'

" Use fontawesome icons as signs
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '>'
let g:gitgutter_sign_removed = '-'
let g:gitgutter_sign_removed_first_line = '^'
let g:gitgutter_sign_modified_removed = '<'

source ~/.vimrc " Load vim settings
