#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi

if which vim >/dev/null; then
  xvim="vim"
elif which vimx >/dev/null; then
  xvim="vimx"
else
  echo "There is no vim"
  exit 1
fi

$xvim -d "$MY_CONFIG_HOME/vim/vim/vimrc" "$HOME/.vimrc"

if read -qs REPLY\?"Press [y] restore vimrc"; then
  cp "$MY_CONFIG_HOME/vim/vim/vimrc" "$HOME/.vimrc"
  printf "\n\033[0;32mRestore vimrc finished\033[0m\n"
fi

if echo && read -qs REPLY\?"Press [y] install airline: "; then
	mkdir -p "$HOME/.vim/pack/dist/start/"
	git clone git@github.com:vim-airline/vim-airline.git "$HOME/.vim/pack/dist/start/vim-airline"
elif echo && read -qs REPLY\?"Press [y] install custom statusline: "; then
	cp "$MY_CONFIG_HOME/vim/vim/statusline.vim" "$HOME/.vim/autoload/"
fi

if echo && read -qs REPLY\?"Press [y] install easymotion: "; then
	mkdir -p "$HOME/.vim/pack/plugins/start/"
	git clone git@github.com:easymotion/vim-easymotion.git ~/.vim/pack/plugins/start/vim-easymotion
fi

if echo && read -qs REPLY\?"Press [y] install fzf: "; then
	git clone git@github.com:junegunn/fzf.git ~/.vim/pack/packages/start/fzf
	git clone git@github.com:junegunn/fzf.vim.git ~/.vim/pack/packages/start/fzf.vim
fi

if echo && read -qs REPLY\?"Press [y] install vim-visual-multi: "; then
	mkdir -p "$HOME/.vim/pack/plugins/start/"
  git clone git@github.com:mg979/vim-visual-multi.git ~/.vim/pack/packages/start/vim-visual-multi
fi
