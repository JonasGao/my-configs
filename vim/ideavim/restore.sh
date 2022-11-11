#!/bin/bash
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
cp "$MY_CONFIG_HOME/vim/ideavim/user.vim" "$HOME/.ideavimrc"
cp "$MY_CONFIG_HOME/vim/ideavim/backup.sh" "$HOME/.local/bin/backup-my-ideavimrc"
printf "\033[0;32mRestore ideavimrc finished\033[0m\n"
