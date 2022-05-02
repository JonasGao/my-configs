""" Plugins ---------------------------
set surround
set multiple-cursors
set commentary
set argtextobj
set easymotion
set textobj-entire
set ReplaceWithRegister

""" Plugin settings -------------------
let g:argtextobj_pairs="[:],(:),<:>"

""" Common settings -------------------
set showmode
set scrolloff=5
set incsearch
set nu rnu

""" Idea specific settings ------------
set ideajoin
set ideastatusicon=gray
set idearefactormode=keep

""" Mappings --------------------------
map Q gq

let mapleader = "\\"
vmap <leader>y "*y
nmap <leader>p "*p
vmap <leader>p "*p
nmap <leader>r <Action>(ReformatCode)
map <leader>f <Action>(GotoFile)
map <leader>g <Action>(FindInPath)
map <leader>b <Action>(Switcher)
