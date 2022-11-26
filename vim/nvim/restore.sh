#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
mkdir -p "$HOME/.config/nvim/"
cp "$MY_CONFIG_HOME/vim/nvim/init.vim" "$HOME/.config/nvim/init.vim"
printf "\033[0;32mRestore neovim config files finished.\033[0m\n"

if echo && read -qs REPLY\?"Press [y] install airline: "; then
	mkdir -p "$HOME/.config/nvim/pack/dist/start/"
	git clone git@github.com:vim-airline/vim-airline.git "$HOME/.config/nvim/pack/dist/start/vim-airline"
fi

if echo && read -qs REPLY\?"Press [y] install easymotion: "; then
	mkdir -p "$HOME/.config/nvim/pack/dist/start/"
	git clone git@github.com:easymotion/vim-easymotion.git "$HOME/.config/nvim/pack/dist/start/vim-easymotion"
fi
