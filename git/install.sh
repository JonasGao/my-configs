#!/bin/bash
RED="\033[0;31m"
GRE="\033[0;32m"
YLE="\033[0;33m"
NC="\033[0m"

[ -z "$MY_CONFIG_HOME" ] && echo -e "${RED}Not found MY_CONFIG_HOME.${NC}" && exit 1

REPO_FILE="$MY_CONFIG_HOME/git/config"
USER_FILE="$HOME/.gitconfig"

# 本机没有配置文件，直接复制
if [ ! -f "$USER_FILE" ]; then
	cp -v "$REPO_FILE" "$USER_FILE"
	echo -e "${GRE}Installed .gitconfig.${NC}"
else
	# 对比两个文件
	if diff -q "$REPO_FILE" "$USER_FILE" >/dev/null 2>&1; then
		echo -e "${GRE}.gitconfig already up to date, skipping.${NC}"
	else
		echo -e "${YLE}Difference found between $REPO_FILE and $USER_FILE:${NC}"
		echo
		diff -u "$USER_FILE" "$REPO_FILE" --color=auto 2>/dev/null || diff -u "$USER_FILE" "$REPO_FILE"
		echo
	fi
fi

# install delta
if ! command -v delta &>/dev/null; then
	if which cargo &>/dev/null; then
		echo -e "${YLE}Install delta from cargo...${NC}"
		cargo install git-delta
	fi
fi
