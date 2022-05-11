""" Plugins ---------------------------
set surround
set multiple-cursors
set commentary
set argtextobj
"set easymotion
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
map <leader>r <Action>(ReformatCode)
map <leader>R <Action>(RearrangeCode)
map <leader>f <Action>(GotoFile)
map <leader>c <Action>(GotoClass)
map <leader>g <Action>(FindInPath)
map <leader>b <Action>(Switcher)
map <leader>Ss :source ~/.ideavimrc<CR>
map <leader>So :e ~/.ideavimrc<CR>
map <leader>1 <Action>(GoToTab1)
map <leader>2 <Action>(GoToTab2)
map <leader>3 <Action>(GoToTab3)
map <leader>4 <Action>(GoToTab4)
map <leader>5 <Action>(GoToTab5)
map <leader>mr <Action>(Maven.Reimport)
map <leader>o <Action>(OverrideMethods)
map <leader>q <Action>(QuickJavaDoc)

map <Space>b <Action>(GotoDeclaration)
map <Space>k <Action>(Back)
map <Space>j <Action>(Forward)
map <Space>e <Action>(RecentFiles)

