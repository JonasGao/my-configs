$CURR_BR = $(git symbolic-ref --short HEAD)
git checkout staging
git pull -r
git merge $CURR_BR
git push
git checkout $CURR_BR
