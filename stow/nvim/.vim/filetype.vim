au BufRead,BufNewFile *.nom setfiletype nom
au BufRead,BufNewFile *.py setfiletype python
au BufRead,BufNewFile /etc/nginx/*,/etc/nginx/conf.d/*,/usr/local/nginx/conf/* if &ft == '' | set filetype=nginx | endif
