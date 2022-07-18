""" Plugins ---------------------------
set NERDTree
set surround
set multiple-cursors
set commentary
set argtextobj
set easymotion
set textobj-entire
set ReplaceWithRegister
set which-key

""" Plugin settings -------------------
let g:argtextobj_pairs="[:],(:),<:>"

""" Common settings -------------------
set showmode
set scrolloff=5
set incsearch
set nu rnu
set timeoutlen=2000

""" Idea specific settings ------------
set ideajoin
set ideastatusicon=gray
set idearefactormode=keep

""" Mappings --------------------------
map Q gq

let mapleader = "\\"
vmap <leader>y "*y
vmap <C-c> "*y
nmap <leader>p "*p
vmap <leader>p "*p
map <leader>rf <Action>(ReformatCode)
map <leader>rr <Action>(RearrangeCode)
map <leader>re <Action>(RenameElement)
map <leader>rt <Action>(SurroundWith)
map <leader>N <Action>(GotoFile)
map <leader>n <Action>(GotoClass)
map <leader>g <Action>(FindInPath)
map <leader>b <Action>(Switcher)
map <leader>mr <Action>(Maven.Reimport)
map <leader>o <Action>(OverrideMethods)
map <leader>q <Action>(QuickJavaDoc)
map <leader>t <Action>(Vcs.UpdateProject)
map <leader>k <Action>(CheckinProject)
map <leader>K <Action>(Vcs.Push)
map <leader>a ggvG$
map <leader>l <Action>(ParameterInfo)

map <leader>Ss :source ~/.ideavimrc<CR>
map <leader>So :e ~/.ideavimrc<CR>

map <leader>1 <Action>(GoToTab1)
map <leader>2 <Action>(GoToTab2)
map <leader>3 <Action>(GoToTab3)
map <leader>4 <Action>(GoToTab4)
map <leader>5 <Action>(GoToTab5)


map <Space>b <Action>(GotoDeclaration)
map <Space>k <Action>(Back)
map <Space>j <Action>(Forward)
map <Space>e <Action>(RecentFiles)
map <Space>B <Action>(GotoImplementation)
map <Space>f <Action>(FileStructurePopup)
map <Space>v <Action>(SelectInProjectView)
map <Space>p :NERDTree<CR>
