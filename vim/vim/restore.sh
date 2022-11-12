#!/bin/bash
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
cp "$MY_CONFIG_HOME/vim/vim/vimrc" "$HOME/.vimrc"
printf "\033[0;32mRestore vimrc finished\033[0m\n"
