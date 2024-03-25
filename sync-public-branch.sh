#!/usr/bin/env bash

GIT_DEFAULT_BRANCH=main

## ref: https://intoli.com/blog/exit-on-errors-in-bash-scripts/
# exit when any command fails
set -e

function gitcommitpush() {
  local LOCAL_BRANCH="$(git symbolic-ref --short HEAD)" && \
  local REMOTE_AND_BRANCH=$(git rev-parse --abbrev-ref ${LOCAL_BRANCH}@{upstream}) && \
  IFS=/ read REMOTE REMOTE_BRANCH <<< ${REMOTE_AND_BRANCH} && \
  echo "Staging changes:" && \
  git add -A || true && \
  echo "Committing changes:" && \
  git commit -am "group updates to public branch" || true && \
  echo "Pushing branch '${LOCAL_BRANCH}' to remote origin branch '${LOCAL_BRANCH}':" && \
  git push -f origin ${LOCAL_BRANCH} || true && \
  echo "Pushing branch '${LOCAL_BRANCH}' to remote '${REMOTE}' branch '${REMOTE_BRANCH}':" && \
  git push -f -u ${REMOTE} ${LOCAL_BRANCH}:${REMOTE_BRANCH} || true
}

function gitresetpublicsub() {
  echo "Resetting/re-initializing submodule for public branch" && \
  git submodule deinit -f . && \
  rm -fr ansible && \
  git submodule add -branch main --force --name ansible-github https://github.com/lj020326/ansible-datacenter.git ansible && \
  git config -f .gitmodules submodule.ansible.branch main && \
  echo "Pull latest changes from submodules:" && \
  git submodule update --init --recursive --remote && \
  gitcommitpush
}

## https://www.pixelstech.net/article/1577768087-Create-temp-file-in-Bash-using-mktemp-and-trap
TMP_DIR=$(mktemp -d -p ~)

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT
trap 'rm -fr "$TMP_DIR"' EXIT

GIT_REMOVE_CACHED_FILES=0

CONFIRM=0
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

#PROJECT_DIR="$( cd "$SCRIPT_DIR/../../../" && pwd )"
#PROJECT_DIR="$( pwd . )"
#PROJECT_DIR=$(git rev-parse --show-toplevel)
#PROJECT_DIR="$( cd "$SCRIPT_DIR/" && git rev-parse --show-toplevel )"
PROJECT_DIR="$( git rev-parse --show-toplevel )"

PUBLIC_GITIGNORE=pub.gitignore
PUBLIC_GITMODULES=pub.gitmodules

## ref: https://stackoverflow.com/questions/53839253/how-can-i-convert-an-array-into-a-comma-separated-string
declare -a EXCLUDES_ARRAY
EXCLUDES_ARRAY=('.git')
EXCLUDES_ARRAY+=('.gitmodule')
EXCLUDES_ARRAY+=('.idea')
EXCLUDES_ARRAY+=('.vscode')
EXCLUDES_ARRAY+=('**/.DS_Store')
EXCLUDES_ARRAY+=('venv')
EXCLUDES_ARRAY+=('*.log')
EXCLUDES_ARRAY+=('ansible')

printf -v EXCLUDES '%s,' "${EXCLUDES_ARRAY[@]}"
EXCLUDES="${EXCLUDES%,}"
echo "EXCLUDES=${EXCLUDES}"

echo "SCRIPT_DIR=[${SCRIPT_DIR}]"
echo "PROJECT_DIR=${PROJECT_DIR}"
echo "TMP_DIR=${TMP_DIR}"

## https://serverfault.com/questions/219013/showing-total-progress-in-rsync-is-it-possible
## https://www.studytonight.com/linux-guide/how-to-exclude-files-and-directory-using-rsync
RSYNC_OPTS_GIT_MIRROR=(
    -dar
    --links
    --delete-excluded
    --exclude={"${EXCLUDES}"}
)

RSYNC_OPTS_GIT_UPDATE=(
    -ari
    --links
)

git fetch --all
git checkout ${GIT_DEFAULT_BRANCH}

#RSYNC_OPTS=${RSYNC_OPTS_GIT_MIRROR[@]}

echo "copy project to temporary dir $TMP_DIR"
#rsync_cmd="rsync ${RSYNC_OPTS} ${PROJECT_DIR}/ ${TMP_DIR}/"
rsync_cmd="rsync ${RSYNC_OPTS_GIT_MIRROR[@]} ${PROJECT_DIR}/ ${TMP_DIR}/"
echo "${rsync_cmd}"
eval $rsync_cmd

echo "Checkout public branch"
git checkout public

if [ $GIT_REMOVE_CACHED_FILES -eq 1 ]; then
  echo "Removing files cached in git"
  git rm -r --cached .
fi

#echo "Removing existing non-dot files for clean sync"
#rm -fr *

echo "Copy ${TMP_DIR} to project dir $PROJECT_DIR"
#echo "rsync ${RSYNC_OPTS_GIT_UPDATE[@]} ${TMP_DIR}/ ${PROJECT_DIR}/"
rsync_cmd="rsync ${RSYNC_OPTS_GIT_UPDATE[@]} ${TMP_DIR}/ ${PROJECT_DIR}/"
echo "${rsync_cmd}"
eval $rsync_cmd

mirrorDirList="
.github
docs
inspec
templates
tools
"

IFS=$'\n'
for dir in ${mirrorDirList}
do
  echo "Mirror ${TMP_DIR}/${dir}/ to project dir $PROJECT_DIR/${dir}/"
  rsync_cmd="rsync ${RSYNC_OPTS_GIT_UPDATE[@]} --delete --update --exclude=save ${TMP_DIR}/${dir}/ ${PROJECT_DIR}/${dir}/"
  echo "${rsync_cmd}"
  eval $rsync_cmd
done

if [ -e $PUBLIC_GITIGNORE ]; then
  echo "Update public files:"
  cp -p $PUBLIC_GITIGNORE .gitignore
fi

if [ -e $PUBLIC_GITMODULES ]; then
  echo "Update public submodules:"
  cp -p $PUBLIC_GITMODULES .gitmodules
  git submodule deinit -f . && \
  git submodule update --init --recursive --remote
fi

echo "Show changes before push:"
git status

#exit 0

## https://stackoverflow.com/questions/5989592/git-cannot-checkout-branch-error-pathspec-did-not-match-any-files-kn
## git diff --name-only public ${GIT_DEFAULT_BRANCH} --

if [ $CONFIRM -eq 0 ]; then
  ## https://www.shellhacks.com/yes-no-bash-script-prompt-confirmation/
  read -p "Are you sure you want to merge the changes above to public branch ${TARGET_BRANCH}? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
      exit 1
  fi
fi

## https://stackoverflow.com/questions/5738797/how-can-i-push-a-local-git-branch-to-a-remote-with-a-different-name-easily
echo "Add all the files:"
gitcommitpush

echo "Finally, checkout ${GIT_DEFAULT_BRANCH} branch:" && \
git checkout ${GIT_DEFAULT_BRANCH}

echo "Resetting ansible submodule for private"
git submodule deinit -f . && \
git submodule update --init --recursive --remote
#gitcommitpush

chmod +x *.sh
