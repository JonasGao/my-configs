#!/bin/zsh

NVIM_CONF_HOME="$HOME/.config/nvim"
PACK_HOME="$NVIM_CONF_HOME/pack"
PACK_START="$PACK_HOME/dist/start"

if [ -z "$MY_CONFIG_HOME" ]
then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi

mkdir -p "$HOME/.config/nvim/"

rercfile() {
  SRC="$MY_CONFIG_HOME/vim/nvim/init.vim"
  DST="$HOME/.config/nvim/init.vim"
  nvim -d $DST $SRC
  cp $SRC $DST
  printf "\033[0;32mRestore neovim config files finished.\033[0m\n"
}

install-packer() {
  D="$PACK_START/packer.nvim"
  if [ -d "$D" ]
  then
    exit 2
  fi
  git clone https://github.com/wbthomason/packer.nvim $D
}

cloneplg() {
  NAME=$1
  REPO=$2
  if echo && read -qs REPLY\?"Press [y] install \"$NAME\": "
  then
    mkdir -p "$PACK_START/"
    git clone "git@github.com:$REPO.git" "$PACK_START/$NAME"
  fi
}

reconf() {
  N="$MY_CONFIG_HOME/vim/nvim"
  L="$N/lua"
  P="$N/plugin"
  F="$N/after"
  cp -R $L "$NVIM_CONF_HOME/"
  cp -R $P "$NVIM_CONF_HOME/"
  cp -R $F "$NVIM_CONF_HOME/"
}

while getopts "arpck" OPT
do
  case "$OPT" in
    a)
      ALL=1
      ;;
    r)
      INIT=1
      ;;
    p)
      PLUGIN=1
      ;;
    c)
      CONFIG=1
      ;;
    k)
      PACKER=1
      ;;
    ?)
      echo "arpck" >&2
      exit 3
      ;;
  esac
done

if [ "$ALL" = "1" ]
then
  INIT=1
  PLUGIN=1
  PACKER=1
  CONFIG=1
fi

if [ "$INIT" = "1" ]
then
  rercfile
fi

if [ "$PACKER" = "1" ]
then
  install-packer
fi

if [ "$PLUGIN" = "1" ]
then
  # Replaced by lualine
  # Install-Plugin -Name airline vim-airline/vim-airline
  cloneplg easymotion easymotion/vim-easymotion
  cloneplg fzf junegunn/fzf
  cloneplg fzf.vim junegunn/fzf.vim
  cloneplg vim-visual-multi mg979/vim-visual-multi
fi

if [ "$CONFIG" = "1" ]
then
  reconf
fi
