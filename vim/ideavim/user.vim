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
set timeoutlen=3000

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

map <leader>g <Action>(FindInPath)
map <leader>b <Action>(Switcher)
map <leader>mr <Action>(Maven.Reimport)
map <leader>1    <Action>(GoToTab1)
map <leader>2    <Action>(GoToTab2)
map <leader>3    <Action>(GoToTab3)
map <leader>4    <Action>(GoToTab4)
map <leader>5    <Action>(GoToTab5)

map <Space>b     <Action>(GotoDeclaration)
map <Space>k     <Action>(Back)
map <Space>j     <Action>(Forward)
map <Space>h     <Action>(PreviousTab)
map <Space>l     <Action>(NextTab)
map <Space>e     <Action>(RecentFiles)
map <Space>B     <Action>(GotoImplementation)
map <Space>f     <Action>(FileStructurePopup)
map <Space>v     <Action>(SelectInProjectView)
map <Space>p     :NERDTree<CR>
map <Space>w     <Action>(CloseContent)
map <Space>N     <Action>(GotoFile)
map <Space>n     <Action>(GotoClass)
map <Space>q     <Action>(ParameterInfo)
map <Space>a     ggvG$
map <Space>o     <Action>(OverrideMethods)
map <Space>q     <Action>(QuickJavaDoc)
map <Space>gc    <Action>(CheckinProject)
map <Space>gp    <Action>(Vcs.Push)
map <Space>gf    <Action>(Vcs.UpdateProject)
map <Space>Ss    :source ~/.ideavimrc<CR>
map <Space>So    :e ~/.ideavimrc<CR>
map <Space>rf    <Action>(ReformatCode)
map <Space>rr    <Action>(RearrangeCode)
map <Space>re    <Action>(RenameElement)
map <Space>rt    <Action>(SurroundWith)
