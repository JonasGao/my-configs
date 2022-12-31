set nu rnu
set background=dark
set signcolumn=yes
set ttimeoutlen=0
set wildmenu wildmode=longest:full,full
set completeopt=noinsert,noselect
set clipboard=unnamedplus
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

""" Unknown command
"set title
"set inccommand=split

filetype plugin indent on
syntax on

""" Basic mapping
nnoremap  dw  vb"_d
nnoremap  <Space>a  ggvG$
nnoremap  te  :tabedit<Return>

""" Leaders mapping
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
nnoremap  <Leader>ss  :split<Return><C-w>w
nnoremap  <Leader>sv  :vsplit<Return><C-w>w

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
nnoremap 	ma  <Plug>(easymotion-overwin-f)
nnoremap 	ms 	<Plug>(easymotion-overwin-f2)
nnoremap 	mj 	<Plug>(easymotion-j)
nnoremap 	mk 	<Plug>(easymotion-k)

""" Load Packer
lua require('plugins')
