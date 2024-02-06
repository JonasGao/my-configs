#!/bin/bash
RED="\033[0;31m"
GRE="\033[0;32m"
YLE="\033[0;33m"
NC="\033[0m"
[ -z "$MY_CONFIG_HOME" ] && echo -e "${RED}Not found MY_CONFIG_HOME.${NC}" && exit 1
REPO_FILE="$MY_CONFIG_HOME/git/config"
USER_FILE="$HOME/.gitconfig"
[ ! -f "$USER_FILE" ] && echo -e "${RED}$USER_FILE already exists.${NC}" && exit 2
cp -v "$REPO_FILE" "$USER_FILE"
echo -e "${GRE}Installed .gitconfig.${NC}"

# install delta
if ! command -v delta &> /dev/null; then
  if which cargo &> /dev/null; then
    echo -e "${YLE}Install delta from cargo...${NC}"
    cargo install git-delta
  fi
fi
