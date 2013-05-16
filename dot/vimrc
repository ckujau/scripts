"
" ~/.vimrc
"
set background=dark		" Use 'light' otherwise
set encoding=utf-8
set tabstop=4			" Instead of 8 spaces
set ruler				" Show ruler
set showcmd				" Show (partial) command in status line
set showmatch			" Show matching brackets
set noincsearch			" No incremental search
set nohlsearch			" Don't highlight search results
set nolist				" Don't show tabs
set nonumber			" Don't show line numbers
set t_ti= t_te=			" Don't blank on exit

" Syntax highlighting
if has("syntax")
	syntax on
	colorscheme slate
endif

" Jump to the last cursor position upon reopening a file
if has("autocmd")
	autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif
