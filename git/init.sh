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
git config --global alias.cm 'commit -m'
git config --global alias.ca 'commit -a'
git config --global alias.cam 'commit -a -m'
git config --global alias.st status
git config --global alias.pt 'push --tags'
git config --global alias.pr 'pull -r'
echo "Alias setup completion"

echo "Setup default editor: vim"
git config --global core.editor vim
