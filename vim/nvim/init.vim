set nu rnu
set title
set background=dark
set signcolumn=yes
set ttimeoutlen=0
set wildmenu wildmode=longest:full,full
set completeopt=noinsert,menuone,noselect
set inccommand=split
set clipboard+=unnamedplus
set backspace=indent,eol,start
"set list
"set listchars=eol:⏎,tab:␉·,trail:␠,nbsp:⎵
set list listchars=tab:»-,trail:·,extends:»,precedes:«
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
nnoremap	<Leader>n	:set nu! rnu!<CR>
nnoremap	<Leader>w	:set wrap!<CR>
nnoremap	<Leader>m	:set filetype=
" Switch buffer
nnoremap	<Leader>h :bp<CR>
nnoremap	<Leader>l :bn<CR>
nnoremap  <Leader>b :ls<CR>
nnoremap  <Leader>1 :b1<CR>
nnoremap  <Leader>2 :b2<CR>
nnoremap  <Leader>3 :b3<CR>
nnoremap  <Leader>4 :b4<CR>
nnoremap  <Leader>5 :b5<CR>
nnoremap  <Leader>6 :b6<CR>
nnoremap  <Leader>7 :b7<CR>
nnoremap  <Leader>8 :b8<CR>
nnoremap  <Leader>9 :b9<CR>
" Split
nnoremap  <Leader>ss  :split<Return><C-w>w
nnoremap  <Leader>sv  :vsplit<Return><C-w>w
" Resize
nnoremap  <Leader>W,  <C-w><
nnoremap  <Leader>W.  <C-w>>
" Switch foldmethod
nnoremap	<Leader>zs	:set foldmethod=syntax<CR>
nnoremap	<Leader>zi	:set foldmethod=indent<CR>
nnoremap	<Leader>zm	:set foldmethod=manual<CR>
nnoremap	<Leader>zk	:set foldmethod=marker<CR>
nnoremap	<Leader>Z	  :set nofoldenable<CR>
" Insert current date
nnoremap  <Leader>id  :r!date<CR>
inoremap  <C-p>d      <C-r>=system('date')<CR>

""" Setup color
if has('win32')
	set termguicolors
elseif $TERM ==? 'xterm-256color'
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
