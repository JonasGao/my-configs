$NVIM_CONF_HOME="$HOME/AppData/Local/nvim"
$PACK_HOME="$NVIM_CONF_HOME/pack"
$PACK_START="$PACK_HOME/dist/start"

if (-not(Test-Path Variable:\MY_CONFIG_HOME)) {
	throw "There is no MY_CONFIG_HOME"
}
New-Item -Type Container -Force "$NVIM_CONF_HOME"
Copy-Item "$MY_CONFIG_HOME/vim/nvim/init.vim" "$NVIM_CONF_HOME/init.vim"
Write-Host -ForegroundColor Green "Restore neovim config files finished."

#if echo && read -qs REPLY\?"Press [y] install airline: "; then
#	mkdir -p "$PACK_START/"
#	git clone git@github.com:vim-airline/vim-airline.git "$PACK_START/vim-airline"
#fi
#
#if echo && read -qs REPLY\?"Press [y] install easymotion: "; then
#	mkdir -p "$PACK_START/"
#	git clone git@github.com:easymotion/vim-easymotion.git "$PACK_START/vim-easymotion"
#fi
#
#if echo && read -qs REPLY\?"Press [y] install fzf: "; then
#	mkdir -p "$PACK_START/"
#	git clone git@github.com:junegunn/fzf.git "$PACK_START/fzf"
#	git clone git@github.com:junegunn/fzf.vim.git "$PACK_START/fzf.vim"
#fi
#
#if echo && read -qs REPLY\?"Press [y] install vim-visual-multi: "; then
#	mkdir -p "$PACK_START/"
#  git clone git@github.com:mg979/vim-visual-multi.git "$PACK_START/vim-visual-multi"
#fi
