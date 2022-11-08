#!/bin/bash
cp "$HOME/.ideavimrc" "$HOME/my_github/my-configs/vim/ideavim/user.vim"
cp "$HOME/.local/bin/backup-my-ideavimrc" "$HOME/my_github/my-configs/vim/ideavim/backup.sh"
cd "$HOME/my_github/my-configs"
git add vim
git commit -m 'Backup ideavimrc'
git push
printf "\033[0;32mBackup ideavimrc finished\033[0m\n"
