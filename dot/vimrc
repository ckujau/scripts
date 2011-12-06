"
" ~/.vimrc
"
syntax on		" May not be supported
set background=dark	" Use 'light' otherwise
set encoding=utf-8
set ruler
set showcmd		" Show (partial) command in status line
set showmatch		" Show matching brackets
set noincsearch		" Incremental search sucks
set t_ti= t_te=		" Don't blank on exit

" Jump to the last cursor position upon resume
autocmd BufReadPost *
	\ if line("'\"") > 1 && line("'\"") <= line("$") |
	\   exe "normal! g`\"" |
	\ endif
