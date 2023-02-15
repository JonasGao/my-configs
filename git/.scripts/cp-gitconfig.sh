#!/bin/bash
if [ -z "$MY_CONFIG_HOME" ]; then
  printf "\033[0;31mNon MY_CONFIG_HOME\033[0m"
  exit 1
fi
REPO_FILE="$MY_CONFIG_HOME/git/.gitconfig"
USER_FILE="$HOME/.gitconfig"
if [ -f "$USER_FILE" ]; then
  echo "Found exists .gitconfig"
  read -re -n 1 -p "Do you want to remove and link? [y]" r
  if [ "$r" = "y" ] ; then
    rm "$USER_FILE"
  else
    echo "Abort."
    exit 0
  fi
fi
ln -s "$REPO_FILE" "$USER_FILE"
printf "\033[0;32mCopy .gitconfig.\033[0m\n"
