#!/bin/bash

printf """
1. Copy GitConfig
2. Install Delta
"""

read -re -n 1 -p "Choose [12]:" r
case $r in
  1)
    .scripts/cp-gitconfig.sh
    ;;
  2)
    .scripts/install-delta.sh
    ;;
  ?)
    echo "Not match"
    ;;
esac
