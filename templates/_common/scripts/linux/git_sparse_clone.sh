#!/usr/bin/env bash

## ref: https://stackoverflow.com/questions/600079/how-do-i-clone-a-subdirectory-only-of-a-git-repository
function git_sparse_clone() (
  rurl="$1" rbranch="$2" localdir="$3" && shift 3

  mkdir -p "$localdir"
  cd "$localdir"

  git init
  git remote add -f origin "$rurl"

  git config core.sparseCheckout true

  # Loops over remaining args
  for i; do
    echo "$i" >> .git/info/sparse-checkout
  done

  git pull origin "${rbranch}"
)

git_sparse_clone "${@}"
##
## example:
#echo "==> Perform sparse clone of dcc_common"
## git_sparse_clone "http://github.com/tj/n" "main" "./local/location" "/bin"
