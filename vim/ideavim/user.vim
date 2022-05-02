set scrolloff=5
set incsearch
set nu rnu

map Q gq

let mapleader = "\\"
vmap <leader>y "*y
nmap <leader>p "*p
vmap <leader>p "*p
nmap <leader>r <Action>(ReformatCode)
map <leader>f <Action>(GotoFile)
map <leader>g <Action>(FindInPath)
map <leader>b <Action>(Switcher)
