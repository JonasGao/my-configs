#!/bin/bash

if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi

REPO_CONF_FILE="$MY_CONFIG_HOME/vim/ideavim/.ideavimrc"
USER_CONF_FILE="$HOME/.ideavimrc"

resolve_diff() {
  if [ -z "$diff_tool" ]; then
    if which delta; then
      diff_tool="delta"
    elif which nvim; then
      diff_tool="nvim -d"
    elif which vim; then
      diff_tool="vim -d"
    else
      diff_tool="vi -d"
    fi
  fi
}

do_diff() {
  resolve_diff
  eval "$diff_tool $1 $2"
}

if [ -f "$USER_CONF_FILE" ]; then
  echo "Found exists .ideavimrc"
  read -re -n 1 -p "Do you want to diff it first? [y]" r
  if [ "$r" = "y" ]; then
    do_diff "$REPO_CONF_FILE" "$USER_CONF_FILE"
  fi
  read -re -n 1 -p "Do you want to continues? [y]" r
  if [ "$r" != "y" ]; then
    exit 0
  fi
  rm "$USER_CONF_FILE"
elif [ -L "$USER_CONF_FILE" ]; then
  printf "\033[0;33mAlready linked.\033[0m\n"
  exit 0
fi

ln -s "$REPO_CONF_FILE" "$USER_CONF_FILE"
printf "\033[0;32mRestore ideavimrc finished\033[0m\n"
