#!/usr/bin/env bash

PROJECT_DIR=$( git rev-parse --show-toplevel )

#################################
## For `SUBMODULE_CONFIGS` use the following format to specify submodule configurations:
##
##   [SUBMODULE_NAME|SUBMODULE_BRANCH|SUBMODULE_URL[|SUBMODULE_DIRECTORY]]
##
## Note `SUBMODULE_DIRECTORY` is optional.
## if not specified, it will default to "${SUBMODULE_NAME}/"
##

SUBMODULE_CONFIGS="
ansible|ansible|git@bitbucket.org:lj020326/ansible-datacenter.git
"

refresh_submodules() {

  SUBMODULE_CONFIGS=$1

  local GIT_LOCAL_BRANCH="$(git symbolic-ref --short HEAD)"
  echo "GIT_LOCAL_BRANCH=${GIT_LOCAL_BRANCH}"
  local GIT_REMOTE_AND_BRANCH=$(git rev-parse --abbrev-ref "${GIT_LOCAL_BRANCH}@{upstream}")
  IFS=/ read GIT_REMOTE GIT_REMOTE_BRANCH <<< "${GIT_REMOTE_AND_BRANCH}"

  ##
  ## for each PATH iteration create a soft link back to all files found in the respective base directory (Sandbox/Prod)
  ##
  IFS=$'\n'
  for SUBMODULE_CONFIG in ${SUBMODULE_CONFIGS}
  do

    echo "#######################################################"
    echo "#######################################################"
    echo "##### Create submodule for SUBMODULE_CONFIG [$SUBMODULE_CONFIG]"
    # split sub-list if available
    if [[ $SUBMODULE_CONFIG == *"|"* ]]
    then
      # ref: https://stackoverflow.com/questions/12317483/array-of-arrays-in-bash
      # split submodule info from sub-list
#      SUBMODULE_CONFIG_ARRAY=(${submodule_config//:/})
      IFS="|" read -a SUBMODULE_CONFIG_ARRAY <<< "$SUBMODULE_CONFIG"
      SUBMODULE_NAME=${SUBMODULE_CONFIG_ARRAY[0]}
      SUBMODULE_URL=${SUBMODULE_CONFIG_ARRAY[2]}
      SUBMODULE_DIRECTORY="${SUBMODULE_NAME}/"

#      if [[ -n "$SUBMODULE_CONFIG_ARRAY[3]" ]]; then
      if [[ -v "SUBMODULE_CONFIG_ARRAY[3]" ]]; then
        SUBMODULE_DIRECTORY=${SUBMODULE_CONFIG_ARRAY[3]}
      fi
      SUBMODULE_BASEDIR=$(dirname "${SUBMODULE_DIRECTORY}")

      echo "SUBMODULE_NAME=${SUBMODULE_NAME}"
      echo "SUBMODULE_URL=${SUBMODULE_URL}"
      echo "SUBMODULE_BASEDIR=${SUBMODULE_BASEDIR}"
      echo "SUBMODULE_DIRECTORY=${SUBMODULE_DIRECTORY}"

      if [ ! -d "${SUBMODULE_BASEDIR}" ]; then
        mkdir -p "${SUBMODULE_BASEDIR}"
      fi

      git submodule deinit -f "${SUBMODULE_NAME}" > /dev/null 2>&1 || true
      git rm "${SUBMODULE_NAME}" > /dev/null 2>&1 || true
      git rm --cached "${SUBMODULE_NAME}" > /dev/null 2>&1 || true
      rm -fr "${SUBMODULE_DIRECTORY}"

      ## ref: https://stackoverflow.com/questions/55031993/git-submodule-tracking-current-branch
#      git submodule add \
#        -b "${GIT_REMOTE_BRANCH}" \
      git submodule add \
        --force \
        --name "${SUBMODULE_NAME}" \
        "${SUBMODULE_URL}" \
        "${SUBMODULE_DIRECTORY}"

#      git submodule set-branch --branch . "${SUBMODULE_NAME}"
      git submodule set-branch --branch "${GIT_REMOTE_BRANCH}" "${SUBMODULE_NAME}"
      git submodule update --remote

    fi

  done
  git submodule update --init --recursive --remote

  ## ref: https://stackoverflow.com/questions/12641469/list-submodules-in-a-git-repository#12641787
#  git config --file .gitmodules --name-only --get-regexp path
  git submodule status
}

refresh_submodules "${SUBMODULE_CONFIGS}"
