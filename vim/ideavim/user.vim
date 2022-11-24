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
set clipboard+=unnamed

""" Idea specific settings ------------
set ideajoin
set ideastatusicon=gray
set idearefactormode=keep

""" Mappings --------------------------
map Q gq

let mapleader = "\\"
vnoremap      <leader>y   "*y
vnoremap      <C-c>       "*y
nnoremap      <leader>p   "*p
vnoremap      <leader>p   "*p
nnoremap      <leader>g    <Action>(FindInPath)
nnoremap      <leader>b    <Action>(Switcher)
nnoremap      <leader>mr   <Action>(Maven.Reimport)
nnoremap      <leader>1    <Action>(GoToTab1)
nnoremap      <leader>2    <Action>(GoToTab2)
nnoremap      <leader>3    <Action>(GoToTab3)
nnoremap      <leader>4    <Action>(GoToTab4)
nnoremap      <leader>5    <Action>(GoToTab5)

nnoremap      <Space>b     <Action>(GotoDeclaration)
nnoremap      <Space>k     <Action>(Back)
nnoremap      <Space>j     <Action>(Forward)
nnoremap      <Space>h     <Action>(PreviousTab)
nnoremap      <Space>l     <Action>(NextTab)
nnoremap      <Space>e     <Action>(RecentFiles)
nnoremap      <Space>B     <Action>(GotoImplementation)
nnoremap      <Space>f     <Action>(FileStructurePopup)
nnoremap      <Space>v     <Action>(SelectInProjectView)
nnoremap      <Space>p     :NERDTree<CR>
nnoremap      <Space>w     <Action>(CloseContent)
nnoremap      <Space>N     <Action>(GotoFile)
nnoremap      <Space>n     <Action>(GotoClass)
nnoremap      <Space>q     <Action>(ParameterInfo)
nnoremap      <Space>a     ggvG$
nnoremap      <Space>o     <Action>(OverrideMethods)
nnoremap      <Space>q     <Action>(QuickJavaDoc)
nnoremap      <Space>gc    <Action>(CheckinProject)
nnoremap      <Space>gp    <Action>(Vcs.Push)
nnoremap      <Space>gf    <Action>(Vcs.UpdateProject)
nnoremap      <Space>Ss    :source ~/.ideavimrc<CR>
nnoremap      <Space>So    :e ~/.ideavimrc<CR>
nnoremap      <Space>rf    <Action>(ReformatCode)
nnoremap      <Space>rg    <Action>(RearrangeCode)
nnoremap      <Space>re    <Action>(RenameElement)
nnoremap      <Space>rt    <Action>(SurroundWith)
nnoremap      <Space>rr    <Action>(Refactorings.QuickListPopupAction)
nnoremap      <Space>t     <Action>(Replace)

""" EasyMotion
nnoremap      Ma           <Plug>(easymotion-f)
nnoremap      Ms           <Plug>(easymotion-F)
