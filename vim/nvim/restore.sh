#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
mkdir -p "$HOME/.config/nvim/"
cp "$MY_CONFIG_HOME/vim/nvim/init.vim" "$HOME/.config/nvim/init.vim"
cp "$MY_CONFIG_HOME/vim/nvim/backup.sh" "$HOME/.local/bin/backup-my-nvimrc"
printf "\033[0;32mRestore neovim config files finished.\033[0m\n"
