#!/bin/zsh

PACK_HOME="$HOME/.config/nvim/pack"
PACK_START="$PACK_HOME/dist/start"

if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
mkdir -p "$HOME/.config/nvim/"
cp "$MY_CONFIG_HOME/vim/nvim/init.vim" "$HOME/.config/nvim/init.vim"
printf "\033[0;32mRestore neovim config files finished.\033[0m\n"

if echo && read -qs REPLY\?"Press [y] install airline: "; then
	mkdir -p "$PACK_START/"
	git clone git@github.com:vim-airline/vim-airline.git "$PACK_START/vim-airline"
fi

if echo && read -qs REPLY\?"Press [y] install easymotion: "; then
	mkdir -p "$PACK_START/"
	git clone git@github.com:easymotion/vim-easymotion.git "$PACK_START/vim-easymotion"
fi

if echo && read -qs REPLY\?"Press [y] install fzf: "; then
	mkdir -p "$PACK_START/"
	git clone git@github.com:junegunn/fzf.git "$PACK_START/fzf"
	git clone git@github.com:junegunn/fzf.vim.git "$PACK_START/fzf.vim"
fi

if echo && read -qs REPLY\?"Press [y] install vim-visual-multi: "; then
	mkdir -p "$PACK_START/"
  git clone git@github.com:mg979/vim-visual-multi.git "$PACK_START/vim-visual-multi"
fi
