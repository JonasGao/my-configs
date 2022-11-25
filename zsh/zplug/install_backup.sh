#!/bin/zsh
TARGET="$HOME/.local/bin"
if [ -d "$TARGET" ]; then
	install backup.sh "$TARGET/backup-my-zshrc-zplug"
else
	echo "There is non \"$TARGET\""
	exit 1
fi
