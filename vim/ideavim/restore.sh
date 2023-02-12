#!/bin/bash

if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi

SCRIPT_NAME="$0"
REPO_CONF_FILE="$MY_CONFIG_HOME/vim/ideavim/.ideavimrc"
USER_CONF_FILE="$HOME/.ideavimrc"

usage() {
  echo "Usage $SCRIPT_NAME: [-i|-b]" >&2
  exit 2
}

set_variable() {
  varname=$1
  shift
  if [ -z "${!varname}" ]; then
    eval "$varname=\"$@\""
  else
    echo "Error: $varname already exists."
    exit 3
  fi
}

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

install_rcfile() {
  do_diff "$REPO_CONF_FILE" "$USER_CONF_FILE"
  read -re -p "Press [y] continues" -n 1 r
  if [ "$r" = "y" ]; then
    cp "$REPO_CONF_FILE" "$USER_CONF_FILE"
    printf "\033[0;32mRestore ideavimrc finished\033[0m\n"
  fi
}

backup_rcfile() {
  do_diff "$USER_CONF_FILE" "$REPO_CONF_FILE"
  read -re -p "Press [y] continues" -n 1 r
  if [ "$r" = "y" ]; then
    cp "$USER_CONF_FILE" "$REPO_CONF_FILE"
    printf "\033[0;32mBackup ideavimrc finished\033[0m\n"
  fi
}

while getopts "ib?h" OPT
do
  case "$OPT" in
    i) set_variable ACTION INSTALL;;
    b) set_variable ACTION BACKUP;;
    h|?) usage;;
  esac
done

[ -z "$ACTION" ] && usage

case "$ACTION" in
  INSTALL) install_rcfile;;
  BACKUP)  backup_rcfile;;
esac
