#!/bin/bash

## How to use
# curl https://raw.githubusercontent.com/JonasGao/my-configs/master/git/init.sh --socks5 127.0.0.1:1080 -O init.sh && chmod u+x ./init.sh && ./init.sh && rm ./init.sh
# if no proxy
# curl https://raw.githubusercontent.com/JonasGao/my-configs/master/git/init.sh -O init.sh && chmod u+x ./init.sh && ./init.sh && rm ./init.sh

git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.curr-br git symbolic-ref --short HEAD
git config --global alias.push-new push origin $(git curr-br)

## editor settings
# for mac or linux
# git config --global core.editor vim
# for windows
# use 'C:\\WINDOWS\\gvim.bat' -f -i NONE
