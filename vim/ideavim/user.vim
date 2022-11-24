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
vnoremap     <leader>y   "*y
vnoremap     <C-c>       "*y
nnoremap     <leader>p   "*p
vnoremap     <leader>p   "*p
noremap      <leader>g    <Action>(FindInPath)
noremap      <leader>b    <Action>(Switcher)
noremap      <leader>mr   <Action>(Maven.Reimport)
noremap      <leader>1    <Action>(GoToTab1)
noremap      <leader>2    <Action>(GoToTab2)
noremap      <leader>3    <Action>(GoToTab3)
noremap      <leader>4    <Action>(GoToTab4)
noremap      <leader>5    <Action>(GoToTab5)

noremap      <Space>b     <Action>(GotoDeclaration)
noremap      <Space>k     <Action>(Back)
noremap      <Space>j     <Action>(Forward)
noremap      <Space>h     <Action>(PreviousTab)
noremap      <Space>l     <Action>(NextTab)
noremap      <Space>e     <Action>(RecentFiles)
noremap      <Space>B     <Action>(GotoImplementation)
noremap      <Space>f     <Action>(FileStructurePopup)
noremap      <Space>v     <Action>(SelectInProjectView)
noremap      <Space>p     :NERDTree<CR>
noremap      <Space>w     <Action>(CloseContent)
noremap      <Space>N     <Action>(GotoFile)
noremap      <Space>n     <Action>(GotoClass)
noremap      <Space>q     <Action>(ParameterInfo)
noremap      <Space>a     ggvG$
noremap      <Space>o     <Action>(OverrideMethods)
noremap      <Space>q     <Action>(QuickJavaDoc)
noremap      <Space>gc    <Action>(CheckinProject)
noremap      <Space>gp    <Action>(Vcs.Push)
noremap      <Space>gf    <Action>(Vcs.UpdateProject)
noremap      <Space>Ss    :source ~/.ideavimrc<CR>
noremap      <Space>So    :e ~/.ideavimrc<CR>
noremap      <Space>rf    <Action>(ReformatCode)
noremap      <Space>rg    <Action>(RearrangeCode)
noremap      <Space>re    <Action>(RenameElement)
noremap      <Space>rt    <Action>(SurroundWith)
noremap      <Space>rr    <Action>(Refactorings.QuickListPopupAction)
noremap      <Space>t     <Action>(Replace)

""" EasyMotion
noremap      Ma           <Plug>(easymotion-f)
noremap      Ms           <Plug>(easymotion-F)
