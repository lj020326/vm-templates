#!/usr/bin/env bash

## ref: https://intoli.com/blog/exit-on-errors-in-bash-scripts/
# exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

echo "Check out master branch:"
git checkout master

#echo "Delete current local public branch:"
#git branch -D public

echo "Check out to a temporary branch:"
git checkout --orphan TEMP_BRANCH

echo "Update public files:"
cp pub.gitmodules .gitmodules
rm -fr ansible

## ref: https://www.systutorials.com/how-to-reset-all-submodules-in-git/
git submodule deinit -f .

#git submodule sync --recursive
git submodule update --init --recursive --remote

echo "Add all the files:"
git add -A

echo "Commit the changes:"
git commit -am "Initial commit"

#echo "Merge master changes to public branch:"
#git merge master

echo "Update submodules:"
git submodule sync --recursive
git submodule update --init --recursive --remote

echo "Delete the old branch:"
git branch -D public

echo "Rename the temporary branch to public:"
## ref: https://gist.github.com/heiswayi/350e2afda8cece810c0f6116dadbe651
git branch -m public

echo "Force public branch update to origin repository:"
git push -f origin public
#git push -f --set-upstream origin public

echo "Force public branch update to github repository:"
git push -f github public

echo "Checkout master branch:"
git checkout master

echo "Reset submodule:"
git submodule deinit -f .
rm -fr .git/modules/ansible/
rm -fr ansible/

echo "Resync submodule with internal submodule repo:"
#git submodule sync --recursive
git submodule update --init --recursive --remote

echo "Update internal repo:"
git add .
git commit -m 'post public push - resetting submodule back to private repo'
git push origin

