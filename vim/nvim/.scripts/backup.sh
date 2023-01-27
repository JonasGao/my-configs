#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
cp "$HOME/.config/nvim/init.vim" "$MY_CONFIG_HOME/vim/nvim/init.vim"
cp "$HOME/.local/bin/backup-my-nvimrc" "$MY_CONFIG_HOME/vim/nvim/backup.sh"
cd "$MY_CONFIG_HOME"
git diff
if read -q REPLAY\?"Press [y] to add & commit & push: "; then
	git add vim
	git commit -m 'Backup neovim config'
	git push
	printf "\033[0;32mBackup neovim config finished\033[0m\n"
fi
