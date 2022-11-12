#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
cp "$MY_CONFIG_HOME/vim/vim/vimrc" "$HOME/.vimrc"
printf "\033[0;32mRestore vimrc finished\033[0m\n"

if read -q REPLY\?"Press [y] install airline: "; then
	mkdir -p "$HOME/.vim/pack/dist/start/"
	git clone git@github.com:vim-airline/vim-airline.git "$HOME/.vim/pack/dist/start/vim-airline"
elif read -q REPLY\?"Press [y] install custom statusline: "; then
	cp "$MY_CONFIG_HOME/vim/vim/statusline.vim" "$HOME/.vim/autoload/"
fi
