let mytabstop = 4
let &tabstop=mytabstop
let &softtabstop=mytabstop
let &shiftwidth=mytabstop

set expandtab
set smarttab
set autoindent
set smartindent
set expandtab
syntax enable
set background=dark
set nu rnu
set cursorline
set nobackup
set noswapfile
set nobomb
set hidden

nmap [n :set nu rnu<CR>
nmap ]n :set nonu nornu<CR>
nmap [w :set wrap<CR>
nmap ]w :set nowrap<CR>

hi CursorLine cterm=NONE ctermbg=233
