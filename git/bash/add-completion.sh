#!/bin/bash
cd "$HOME"
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
chmod u+x git-completion.bash
mv git-completion.bash .git-completion.bash
echo "source $HOME/.git-completion.bash" >> .bashrc
source "$HOME/.git-completion.bash"
