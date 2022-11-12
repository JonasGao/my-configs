#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
cp "$HOME/.vimrc" "$MY_CONFIG_HOME/vim/vim/vimrc"
cp "$HOME/.local/bin/backup-my-vimrc" "$MY_CONFIG_HOME/vim/vim/backup.sh"
cd "$MY_CONFIG_HOME"
git diff
if read -q REPLAY\?"Press [y] to add & commit & push: "; then
	git add vim
	git commit -m 'Backup vimrc'
	git push
	printf "\033[0;32mBackup vimrc finished\033[0m\n"
fi
