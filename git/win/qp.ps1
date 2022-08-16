$CURR_BR = git symbolic-ref --short HEAD
git checkout staging
git pull -r
git checkout production
git pull -r
git merge staging
git push
git checkout $CURR_BR
