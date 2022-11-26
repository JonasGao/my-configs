#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi
SRC="$MY_CONFIG_HOME/vim/ideavim/user.vim"
DST="$HOME/.ideavimrc"
vim -d $DST $SRC
if read -qs REPLY\?"Press [y] restore: "; then
  echo
  cp "$SRC" "$DST"
  printf "\033[0;32mRestore ideavimrc finished\033[0m\n"
fi
