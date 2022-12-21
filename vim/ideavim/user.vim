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

let mapleader = "\\"
vnoremap     <leader>y   "*y
vnoremap     <C-c>       "*y
nnoremap     <leader>p   "*p
vnoremap     <leader>p   "*p
noremap      <leader>g    :action FindInPath<CR>
noremap      <leader>b    :action Switcher<CR>
noremap      <leader>mr   :action Maven.Reimport<CR>
noremap      <leader>1    :action GoToTab1<CR>
noremap      <leader>2    :action GoToTab2<CR>
noremap      <leader>3    :action GoToTab3<CR>
noremap      <leader>4    :action GoToTab4<CR>
noremap      <leader>5    :action GoToTab5<CR>

noremap      <Space>b     :action GotoDeclaration<CR>
noremap      <Space>k     :action Back<CR>
noremap      <Space>j     :action Forward<CR>
noremap      <Space>h     :action PreviousTab<CR>
noremap      <Space>l     :action NextTab<CR>
noremap      <Space>e     :action RecentFiles<CR>
noremap      <Space>B     :action GotoImplementation<CR>
noremap      <Space>f     :action FileStructurePopup<CR>
noremap      <Space>v     :action SelectInProjectView<CR>
noremap      <Space>p     :NERDTree<CR>
noremap      <Space>w     :action CloseContent<CR>
noremap      <Space>N     :action GotoFile<CR>
noremap      <Space>n     :action GotoClass<CR>
noremap      <Space>q     :action ParameterInfo<CR>
noremap      <Space>a     ggvG$
noremap      <Space>o     :action OverrideMethods<CR>
noremap      <Space>q     :action QuickJavaDoc<CR>
noremap      <Space>gc    :action CheckinProject<CR>
noremap      <Space>gp    :action Vcs.Push<CR>
noremap      <Space>gf    :action Vcs.UpdateProject<CR>
noremap      <Space>So    :action VimActions<CR>
noremap      <Space>Sa    :action IdeaVim.ReloadVimRc.reload<CR>
noremap      <Space>rf    :action ReformatCode<CR>
noremap      <Space>rg    :action RearrangeCode<CR>
noremap      <Space>re    :action RenameElement<CR>
noremap      <Space>rt    :action SurroundWith<CR>
noremap      <Space>rr    :action Refactorings.QuickListPopupAction<CR>
noremap      <Space>t     :action Replace<CR>
noremap      <Space>p     "0p

noremap      Q            gq

""" EasyMotion
nmap      fa           <Plug>(easymotion-f)
nmap      fs           <Plug>(easymotion-F)

""" AceJump Example
" Press `f` to activate AceJump
"map f <Action>(AceAction)
" Press `F` to activate Target Mode
"map F <Action>(AceTargetAction)
" Press `g` to activate Line Mode
"map g <Action>(AceLineAction)
