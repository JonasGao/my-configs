#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
MSG="Backup zshrc(zplug version)"
cp "$HOME/.zshrc" "$MY_CONFIG_HOME/zsh/zplug/zshrc"
cd "$MY_CONFIG_HOME"
git diff
if read -q REPLAY\?"Press [y] to add & commit & push: "; then
	echo
	git add zsh
	git commit -m "$MSG"
	git push
	printf "\033[0;32m$MSG finished\033[0m\n"
fi
