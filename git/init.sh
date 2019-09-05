#!/bin/bash

## Remote use
# curl -s https://raw.githubusercontent.com/JonasGao/my-configs/master/git/init.sh | bash
## If you need proxy
# curl -s https://raw.githubusercontent.com/JonasGao/my-configs/master/git/init.sh --socks5 127.0.0.1:1080 | bash

printf """
Hello, Git!
This will setup some alias~
"""
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
echo "Setup completion"

## editor settings
# for mac or linux
# git config --global core.editor vim
# for windows
# use 'C:\\WINDOWS\\gvim.bat' -f -i NONE
