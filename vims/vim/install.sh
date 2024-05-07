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
  echo -e "\e[32mSuccess install to ~/.vim/autoload/plug.vim\e[0m"
}

restore_conf() {
  SRC="$CONF_SRC/.vimrc"
  DST="$HOME/.vimrc"
  cp "$SRC" "$DST"
  printf "\e[32mAlready overwrite %s by %s\e[0m\n" "$SRC" "$DST"
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
