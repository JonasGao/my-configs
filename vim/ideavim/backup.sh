#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
cp "$HOME/.ideavimrc" "$MY_CONFIG_HOME/vim/ideavim/user.vim"
cp "$HOME/.local/bin/backup-my-ideavimrc" "$MY_CONFIG_HOME/vim/ideavim/backup.sh"
cd "$MY_CONFIG_HOME"
git diff
if read -q REPLAY\?"Press [y] to add & commit & push: "; then
	git add vim
	git commit -m 'Backup ideavimrc'
	git push
	printf "\033[0;32mBackup ideavimrc finished\033[0m\n"
fi
