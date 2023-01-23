#!/bin/bash
if [ -z "$MY_CONFIG_HOME" ]
then
  echo "There is no MY_CONFIG_HOME" >&2
  exit 1
fi

CONF_SRC="$MY_CONFIG_HOME/vim/vim/plug"

install_plug() {
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

restore_conf() {
  cp "$CONF_SRC/.vimrc" "$HOME/.vimrc"
}

while getopts "ic" OPT
do
  case "$OPT" in
    i)
      install_plug
      ;;
    c)
      restore_conf
      ;;
    ?)
      echo "Flags: -ic" >&2
      ;;
  esac
done
