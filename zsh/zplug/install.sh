#!/bin/bash
[ -z "$MY_CONFIG_HOME" ] && MY_CONFIG_HOME="$(cd ../..; pwd)"
echo "Using MY_CONFIG_HOME=\"$MY_CONFIG_HOME\""
if [ ! -d "$HOME/.zplug" ]; then
  echo -e "\033[032mInstall zplug...\033[0m"
  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi
SRC="$MY_CONFIG_HOME/zsh/zplug/zshrc"
DST="$HOME/.zshrc"
cp -v $SRC $DST
echo -e "\033[0;32mInstalled zshrc(zplug version) finished.\033[0m"
if ! command -v eza &> /dev/null; then
  echo -e "\033[032mInstall eza...\033[0m"
  if command -v cargo &> /dev/null; then
    cargo install eza
  else
    echo -e "\033[31mInstall failure, install need cargo. Please install rust.\033[0m"
    echo -e "\033[33mInstall rust by \"curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh\"\033[0m"
  fi
fi

