" For colemak-dh
noremap h k
noremap j h
noremap k j

" Misc
syntax on		" syntax highlighting
set noerrorbells	" Gets rid of beeping sound

" Information
set showcmd		" Show (partial) command in status line
set showmode       	" Show the current mode
set laststatus=2	" Always show status line
set statusline=%.40F%=%m\ %Y\ Line:\ %3l/%L[%3p%%]

" Navigation
set nu       		" Set line numbering
set scrolloff=5     	" Keep at least 5 lines above/below cursor
set mouse=a         	" Enable mouse usage in all modes
set mousehide       	" Hide the mouse when typing

" Tabs
set expandtab       	" Uses spaces instead of tabs
set tabstop=4       	" Each tab is 4 spaces
set shiftwidth=4   	" Sets the >> and << width
set autoindent

