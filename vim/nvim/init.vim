set nu rnu
set background=dark
set clipboard=unnamedplus
set completeopt=noinsert,menuone,noselect
set cursorline
set hidden
set inccommand=split
set mouse=a
set splitbelow splitright
set title
set ttimeoutlen=0
set wildmenu wildmode=longest:full,full
set nobackup
set noswapfile
set nobomb
set hidden

filetype plugin indent on
syntax on

let mapleader="\\"
noremap   <Leader>y    "*y
nnoremap  <Leader>p    "*p
vnoremap  <Leader>p    "*p
nnoremap  <Leader>x    :set paste<CR>
nnoremap  <Leader>X    :set nopaste<CR>
noremap   <Leader>r    :bro ol<CR>
noremap   <Leader>ss   :source ~/.vimrc<CR>
noremap   <Leader>se   :e ~/.vimrc<CR>
nnoremap  <Leader>fms  :set foldmethod=syntax<CR>
nnoremap  <Leader>fmi  :set foldmethod=indent<CR>
nmap      <Leader>n    :set nu rnu<CR>
nmap      <Leader>N    :set nonu nornu<CR>
nmap      <Leader>w    :set wrap<CR>
nmap      <Leader>W    :set nowrap<CR>

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
nmap 	Ja 		<Plug>(easymotion-overwin-f)
nmap 	Js 		<Plug>(easymotion-overwin-f2)
map 	<Leader>j 	<Plug>(easymotion-j)
map 	<Leader>k 	<Plug>(easymotion-k)
