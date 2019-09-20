"""
" Download this config
" curl https://raw.githubusercontent.com/JonasGao/my-configs/master/vim/mvim/.vimrc -o .vimrc
"""

" Vundle {{{
set nocompatible              " be iMproved, required
filetype off                  " required
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'pangloss/vim-javascript'
Plugin 'kchmck/vim-coffee-script'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'MarcWeber/vim-addon-mw-utils'
Plugin 'tomtom/tlib_vim'
Plugin 'garbas/vim-snipmate'
Plugin 'honza/vim-snippets'
Plugin 'valloric/youcompleteme'
Plugin 'suan/vim-instant-markdown'
Plugin 'mattn/emmet-vim'
Plugin 'Chiel92/vim-autoformat'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'wincent/command-t'
Plugin 'leafgarland/typescript-vim'
Plugin 'chr4/nginx.vim'
Plugin 'scrooloose/nerdtree'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" set airline
let g:airline_theme = "luna"
let g:airline_powerline_fonts = 1

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1

let g:user_emmet_mode='inv'

set laststatus=2
" }}}

" Startup {{{
" instead by vundle section
" filetype indent plugin on

" vim 文件折叠方式为 marker
augroup ft_vim
    au!

    au FileType vim setlocal foldmethod=marker
augroup END
" }}}

" General {{{
set nocompatible
set nobackup
set noswapfile
set history=2048
set autochdir
set whichwrap=b,s,<,>,[,]
set nobomb
set nowrap
set backspace=indent,eol,start whichwrap+=<,>,[,]
" Vim 的默认寄存器和系统剪贴板共享
" set clipboard+=unnamed
" 设置 alt 键不映射到菜单栏
set winaltkeys=no
" }}}

" Lang & Encoding {{{
set fileencodings=utf-8,gbk2312,gbk,gb18030,cp936
set encoding=utf-8
set langmenu=zh_CN
let $LANG = 'en_US.UTF-8'
"language messages zh_CN.UTF-8
" }}}

" GUI {{{
let g:solarized_termcolors=256
color solarized

set t_Co=256
set cursorline
set hlsearch
set number
set background=dark
" 分割出来的窗口位于当前窗口下边/右边
set splitbelow
set splitright
" }}}

" Format {{{
set autoindent
set smartindent
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set foldmethod=indent
syntax on
" }}}

" Keymap {{{
let mapleader=","

nmap <leader>s :source $VIM/.vimrc<cr>
nmap <leader>e0 :e $VIM/.vimrc<cr>
nmap <leader>e1 :e $HOME/.vimrc<cr>
" }}}