#!/bin/zsh
if [ -z "$MY_CONFIG_HOME" ]; then
	echo "NO MY_CONFIG_HOME"
	exit 1
fi

if which vim >/dev/null; then
  xvim="vim"
elif which vimx >/dev/null; then
  xvim="vimx"
else
  echo "There is no vim"
  exit 1
fi

if read -qs REPLY\?"Do you want install zplug first?:[y]"; then
	curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi

SRC="$MY_CONFIG_HOME/zsh/zplug/zshrc"
DST="$HOME/.zshrc"

$xvim -d $DST $SRC
if echo && read -qs REPLY\?"Press [y] restore zshrc(zplug version)"; then
  cp $SRC $DST
  printf "\n\033[0;32mRestore zshrc(zplug version) finished\033[0m\n"
fi
