#!/bin/bash

CURR_BR=$(git symbolic-ref --short HEAD)
STAGING_FROM="master"
STAGING_TO="staging"
MERGING_FROM="merging-$STAGING_FROM"
MERGING_TO="merging-$STAGING_TO"

git branch -D $MERGING_FROM $MERGING_TO
git fetch
git checkout -b $MERGING_FROM "origin/$STAGING_FROM"
git checkout -b $MERGING_TO "origin/$STAGING_TO"
git merge $MERGING_FROM -m "Merge branch '$STAGING_FROM' to '$STAGING_TO'"
git push origin HEAD:$STAGING_TO
git checkout $CURR_BR
git branch -D $MERGING_FROM $MERGING_TO
