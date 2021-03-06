#!/bin/bash

CURR_BR=$(git symbolic-ref --short HEAD)
TARGET_BRANCH="$1"
MASTER_BR="master"
STAGING_BR="staging"

if [ "$TARGET_BRANCH" == "" ]; then
  TARGET_BRANCH="$CURR_BR"
fi

if [ "$TARGET_BRANCH" == "$MASTER_BR" ]; then
  echo "Target can not same with '$MASTER_BR'"
  exit 2
fi

if [ "$TARGET_BRANCH" == "$STAGING_BR" ]; then
  echo "Target can not same with '$STAGING_BR'"
  exit 2
fi

git merging $TARGET_BRANCH &&
  git merged &&
  git staging
