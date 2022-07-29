#!/bin/bash
cp "$HOME/.ideavimrc" "$HOME/my_github/my-configs/vim/ideavim/user.vim"
cp "$HOME/.local/bin/sync-my-ideavimrc" "$HOME/my_github/my-configs/vim/ideavim/sync.sh"
cd "$HOME/my_github/my-configs"
git add vim
git commit -m 'Sync ideavimrc'
git push
printf "\033[0;32mSync ideavimrc finished\033[0m\n"
