#!/bin/bash

## Remote use
# curl -s https://raw.githubusercontent.com/JonasGao/my-configs/master/git/init.sh | bash
## If you need proxy
# curl -s https://raw.githubusercontent.com/JonasGao/my-configs/master/git/init.sh --socks5 127.0.0.1:1080 | bash

echo "Hello, Git!"
echo "Configing alias."
./alias.sh
echo "Setup default editor: vim"
git config --global core.editor vim
echo "Finish"
