#!/bin/bash

if [ ! -e ".merging" ]; then
  echo "No .merging file"
  exit 1
fi

ARR=($(cat .merging))

if [ ! "${#ARR[@]}" == "6" ]; then
  echo "Bad .merging file"
  exit 2
fi

TARGET_BRANCH=${ARR[0]}
MERGE_TO_TARGET=${ARR[1]}
MERGE_FROM_CHECKOUT=${ARR[2]}
MERGE_FROM=${ARR[3]}
MERGE_TO_CHECKOUT=${ARR[4]}
MERGE_TO=${ARR[5]}

git push origin "HEAD:$MERGE_TO_TARGET"
git checkout "$TARGET_BRANCH"
git branch -D "$MERGE_FROM" "$MERGE_TO"

rm -f .merging
