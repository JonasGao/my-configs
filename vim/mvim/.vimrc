fu! SetTab(size)
  let &l:tabstop=a:size
  let &l:softtabstop=a:size
  let &l:shiftwidth=a:size
endfu

" set default tab indent
set expandtab
set smarttab
call SetTab(2)

" set default ui
set t_Co=256
set go-=r
set background=dark
syntax enable
let g:solarized_termcolors=256
color solarized

set nu
set nowrap
set hls
set guifont=Fira\ Code:h12
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

set laststatus=2

