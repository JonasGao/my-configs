$CURR_BR = $(git symbolic-ref --short HEAD)
Write-Host -ForegroundColor Blue "Will merge from '$CURR_BR' to 'staging'"
git checkout staging
git pull -r
git merge $CURR_BR
git push
git checkout $CURR_BR
