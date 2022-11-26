#!/bin/zsh
TARGET="$HOME/.local/bin"
CMD_NAME="backup-my-vimrc"
if [ -d "$TARGET" ]; then
	install backup.sh "$TARGET/$CMD_NAME"
  echo "Already install backup script to \"$TARGET/$CMD_NAME\""
else
	echo "There is non \"$TARGET\""
	exit 1
fi
