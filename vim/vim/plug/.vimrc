set nocompatible
set hidden
set nobackup
set noswapfile
set nobomb
set autochdir
set signcolumn=yes
set whichwrap=b,s,<,>,[,]
set history=2048
set backspace=indent,eol,start whichwrap+=<,>,[,]
set timeoutlen=1200
set wildmenu wildmode=longest:full,full
set clipboard+=unnamed
set nu rnu
"set cursorcolumn
set cursorline
set hlsearch
set guioptions-=T
set guioptions-=m
set guioptions-=L
set guioptions-=r
set guioptions-=b
set autoindent
set smartindent
set expandtab
set smarttab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set guifont=等距更纱黑体_SC:h11:cGB2312:qCLEARTYPE
set fileencodings=utf-8,gbk2312,gbk,gb18030,cp936
set encoding=utf-8
set langmenu=zh_CN
let $LANG = 'en_US.UTF-8'
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim


" 参考
" https://vi.stackexchange.com/questions/23066/change-cursorline-style
" https://stackoverflow.com/questions/8640276/how-do-i-change-my-vim-highlight-line-to-not-be-an-underline
"
"hi CursorColumn ctermbg=242
"hi CursorLine cterm=NONE ctermbg=242
syntax on

""" Basic mappings
nnoremap  dw  vb"_d
nnoremap  <Space>a  ggvG$
nnoremap  te  :tabedit<Return>

""" Leaders mappings
let mapleader="\\"
noremap	  <Leader>y    "+y
nnoremap	<Leader>p    "+p
vnoremap	<Leader>p    "+p
nnoremap	<Leader>x    :set paste!<CR>
noremap	  <Leader>r    :bro ol<CR>
noremap	  <Leader>ss   :source ~/.vimrc<CR>
noremap	  <Leader>se   :e ~/.vimrc<CR>
nnoremap	<Leader>fms  :set foldmethod=syntax<CR>
nnoremap	<Leader>fmi  :set foldmethod=indent<CR>
nnoremap	<Leader>n    :set nu! rnu!<CR>
nnoremap	<Leader>w    :set wrap!<CR>
nnoremap	<Leader>m    :set filetype=
nnoremap	<Leader>h    :bp<CR>
nnoremap	<Leader>l    :bn<CR>

""" WhichKey mappings
nnoremap <silent> <Leader> :WhichKey '\'<CR>
nnoremap <silent> <Space> :WhichKey '<Space>'<CR>

if $TERM ==? 'xterm-256color'
	set termguicolors
endif

""" Italics
let &t_ZH="\e[3m"
let &t_ZR="\e[23m"


""" Load vim-plug
call plug#begin()
Plug 'vim-airline/vim-airline'
Plug 'easymotion/vim-easymotion'
Plug 'mg979/vim-visual-multi'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'liuchengxu/vim-which-key'
Plug 'morhetz/gruvbox'
Plug 'rhysd/vim-healthcheck'
call plug#end()

set bg=dark
colorscheme gruvbox

""" 最后加载一个本地自定义
runtime local.vim

""" EasyMotion
let g:EasyMotion_do_mapping = 0
let g:EasyMotion_smartcase = 1
nnoremap 	ma	<Plug>(easymotion-overwin-f)
nnoremap 	ms 	<Plug>(easymotion-overwin-f2)
noremap 	mj 	<Plug>(easymotion-j)
noremap 	mk 	<Plug>(easymotion-k)
