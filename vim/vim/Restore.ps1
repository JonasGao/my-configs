if (-not(Test-Path Variable:\MY_CONFIG_HOME)) {
  throw "Can not found MY_CONFIG_HOME"
}

nvim -d "$MY_CONFIG_HOME/vim/vim/vimrc" "$HOME/.vimrc"

$REPLY = Read-Host -Prompt "Press [y] restore vimrc"
if ($REPLY -eq "y") {
  Copy-Item -Force "$MY_CONFIG_HOME/vim/vim/vimrc" "$HOME/.vimrc"
  Write-Host -ForegroundColor Green "Restore vimrc finished."
}

#if echo && read -qs REPLY\?"Press [y] install airline: "; then
#	mkdir -p "$HOME/.vim/pack/dist/start/"
#	git clone git@github.com:vim-airline/vim-airline.git "$HOME/.vim/pack/dist/start/vim-airline"
#elif echo && read -qs REPLY\?"Press [y] install custom statusline: "; then
#	cp "$MY_CONFIG_HOME/vim/vim/statusline.vim" "$HOME/.vim/autoload/"
#fi
#
#if echo && read -qs REPLY\?"Press [y] install easymotion: "; then
#	mkdir -p "$HOME/.vim/pack/plugins/start/"
#	git clone git@github.com:easymotion/vim-easymotion.git ~/.vim/pack/plugins/start/vim-easymotion
#fi
#
#if echo && read -qs REPLY\?"Press [y] install fzf: "; then
#	git clone git@github.com:junegunn/fzf.git ~/.vim/pack/packages/start/fzf
#	git clone git@github.com:junegunn/fzf.vim.git ~/.vim/pack/packages/start/fzf.vim
#fi
#
#if echo && read -qs REPLY\?"Press [y] install vim-visual-multi: "; then
#	mkdir -p "$HOME/.vim/pack/plugins/start/"
#  git clone git@github.com:mg979/vim-visual-multi.git ~/.vim/pack/packages/start/vim-visual-multi
#fi
