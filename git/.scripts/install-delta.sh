#!/bin/bash
if which delta; then
  printf "\033[0;33mAlready exists delta. Skip.\033[0m\n"
  exit 0
fi
if which brew; then
  echo "Using brew install delta"
  brew install delta
fi
