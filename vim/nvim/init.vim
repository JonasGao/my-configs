set nu rnu
set background=dark
set signcolumn=yes
set ttimeoutlen=0
set wildmenu wildmode=longest:full,full
set clipboard=unnamedplus
set completeopt=noinsert,menuone,noselect
set backspace=indent,eol,start
set cursorline
set hidden
set mouse=a
set splitbelow splitright
set nobackup
set noswapfile
set nobomb
"set title
"set inccommand=split

filetype plugin indent on
syntax on

let mapleader="\\"
nnoremap	<Leader>y    "*y
nnoremap	<Leader>p    "*p
vnoremap	<Leader>p    "*p
nnoremap	<Leader>x    :set paste<CR>
nnoremap	<Leader>X    :set nopaste<CR>
nnoremap	<Leader>r    :bro ol<CR>
nnoremap	<Leader>fms  :set foldmethod=syntax<CR>
nnoremap	<Leader>fmi  :set foldmethod=indent<CR>
nnoremap	<Leader>n    :set nu rnu<CR>
nnoremap	<Leader>N    :set nonu nornu<CR>
nnoremap	<Leader>w    :set wrap<CR>
nnoremap	<Leader>W    :set nowrap<CR>

if $TERM !=? 'xterm-256color'
	set termguicolors
endif

""" Italics
let &t_ZH="\e[3m"
let &t_ZR="\e[23m"

""" 最后加载一个本地自定义
"runtime vimrc

""" EasyMotion
let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase = 1
nmap 	Ma 		<Plug>(easymotion-overwin-f)
nmap 	Ms 		<Plug>(easymotion-overwin-f2)
map 	<Leader>j 	<Plug>(easymotion-j)
map 	<Leader>k 	<Plug>(easymotion-k)
