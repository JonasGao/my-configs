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
set autoindent
set smartindent
set expandtab
set smarttab
set tabstop=2
set softtabstop=2
set shiftwidth=2

"set title
"set inccommand=split

filetype plugin indent on
syntax on

let mapleader="\\"
nnoremap	<Leader>y	"*y
nnoremap	<Leader>p	"*p
vnoremap	<Leader>p	"*p
nnoremap	<Leader>x	:set paste!<CR>
nnoremap	<Leader>r	:bro ol<CR>
nnoremap	<Leader>fms	:set foldmethod=syntax<CR>
nnoremap	<Leader>fmi	:set foldmethod=indent<CR>
nnoremap	<Leader>n	:set nu! rnu!<CR>
nnoremap	<Leader>w	:set wrap!<CR>
nnoremap	<Leader>m	:set filetype=
nnoremap	<Leader>h :bp<CR>
nnoremap	<Leader>l :bn<CR>
nnoremap  <Space>a  ggvG$

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
nnoremap 	Ma 		<Plug>(easymotion-overwin-f)
nnoremap 	Ms 		<Plug>(easymotion-overwin-f2)
nnoremap 	<Leader>j 	<Plug>(easymotion-j)
nnoremap 	<Leader>k 	<Plug>(easymotion-k)
