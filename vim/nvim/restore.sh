#!/bin/bash

NVIM_CONF_HOME="$HOME/.config/nvim"
PACK_HOME="$NVIM_CONF_HOME/pack"
PACK_START="$PACK_HOME/dist/start"
SCRIPT_NAME="$0"

if [ -z "$MY_CONFIG_HOME" ]
then
  echo "NO MY_CONFIG_HOME"
  exit 1
fi

mkdir -p "$HOME/.config/nvim/"

usage() {
  echo "Usage: $SCRIPT_NAME [-arpch]" >&2
  exit 2
}

set_variable() {
  local varname=$1
  shift
  if [ -z "${!varname}" ]; then
    eval "$varname=\"$@\""
  else
    echo "Error: $varname already set" >&2
    exit 3
  fi
}

restore_rcfile() {
  SRC="$MY_CONFIG_HOME/vim/nvim/init.vim"
  DST="$HOME/.config/nvim/init.vim"
  cp "$SRC" "$DST"
  printf "\033[0;32mRestore from %s to %s.\033[0m\n" "$SRC" "$DST"
}

install_packer() {
  D="$PACK_START/packer.nvim"
  if [ -d "$D" ]
  then
    printf "\033[0;33mPacker already exists.\033[0m\n"
    exit 4
  fi
  git clone https://github.com/wbthomason/packer.nvim "$D"
}

restore_conf() {
  N="$MY_CONFIG_HOME/vim/nvim"
  L="$N/lua"
  P="$N/plugin"
  F="$N/after"
  cp -R $L "$NVIM_CONF_HOME/"
  cp -R $P "$NVIM_CONF_HOME/"
  cp -R $F "$NVIM_CONF_HOME/"
  printf "\033[0;32mRestore config files.\033[0m\n"
}

install_dependencies() {
  # For telescope-fzf-native
  scoop install cmake
  # For treesitter
  scoop install gcc
  # For lsp
  scoop install lua-language-server
  # Maybe for telescope preview
  scoop install bat

  Build-TelescopeFzfNative
}

###########################
# Main script starts here

unset ACTION
while getopts "arpc?h" OPT
do
  case "$OPT" in
    a) set_variable ACTION all ;;
    r) set_variable ACTION restore_rcfile ;;
    c) set_variable ACTION restore_conf ;;
    p) set_variable ACTION install_packer ;;
    h|?) usage ;;
  esac
done

[ -z "$ACTION" ] && usage

eval "$ACTION"
