#!/bin/bash
BASE=$(dirname $0)
SRC="$BASE/aria2.conf"
DST="$HOME/.aria2"
mkdir -p "$DST"
cp -v $SRC $DST
printf "\e[32mSuccess install Aria2 conf.\e[0m\n"
