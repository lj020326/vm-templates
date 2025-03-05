#!/usr/bin/env bash

VERSION="2023.9.30"

#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(dirname "$0")"

## PURPOSE RELATED VARS
#PROJECT_DIR=$( git rev-parse --show-toplevel )
PROJECT_DIR="$(cd "${SCRIPT_DIR}" && git rev-parse --show-toplevel)"

REPO_SYMBOLIC_LINKS=()

#####
REPO_SYMBOLIC_LINKS+=("templates/CentOS/common-build-vars.pkr.hcl:../common-build-vars.pkr.hcl")
REPO_SYMBOLIC_LINKS+=("templates/CentOS/common-vars.json.pkr.hcl:../common-vars.json.pkr.hcl")
REPO_SYMBOLIC_LINKS+=("templates/CentOS/env-vars.DEV.json.pkrvars.hcl:../env-vars.DEV.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/CentOS/env-vars.PROD.json.pkrvars.hcl:../env-vars.PROD.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/CentOS/env-vars.QA.json.pkrvars.hcl:../env-vars.QA.json.pkrvars.hcl")

REPO_SYMBOLIC_LINKS+=("templates/Debian/common-vars.json.pkr.hcl:../common-vars.json.pkr.hcl")
REPO_SYMBOLIC_LINKS+=("templates/Debian/env-vars.DEV.json.pkrvars.hcl:../env-vars.DEV.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/Debian/env-vars.PROD.json.pkrvars.hcl:../env-vars.PROD.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/Debian/env-vars.QA.json.pkrvars.hcl:../env-vars.QA.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/Debian/common-build-vars.pkr.hcl:../common-build-vars.pkr.hcl")

REPO_SYMBOLIC_LINKS+=("templates/RHEL/common-build-vars.pkr.hcl:../common-build-vars.pkr.hcl")
REPO_SYMBOLIC_LINKS+=("templates/RHEL/common-vars.json.pkr.hcl:../common-vars.json.pkr.hcl")
REPO_SYMBOLIC_LINKS+=("templates/RHEL/env-vars.DEV.json.pkrvars.hcl:../env-vars.DEV.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/RHEL/env-vars.PROD.json.pkrvars.hcl:../env-vars.PROD.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/RHEL/env-vars.QA.json.pkrvars.hcl:../env-vars.QA.json.pkrvars.hcl")

REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/common-vars.json.pkr.hcl:../common-vars.json.pkr.hcl")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/env-vars.DEV.json.pkrvars.hcl:../env-vars.DEV.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/env-vars.PROD.json.pkrvars.hcl:../env-vars.PROD.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/env-vars.QA.json.pkrvars.hcl:../env-vars.QA.json.pkrvars.hcl")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/common-build-vars.pkr.hcl:../common-build-vars.pkr.hcl")

REPO_SYMBOLIC_LINKS+=("templates/Debian/7:wheezy64")
REPO_SYMBOLIC_LINKS+=("templates/Debian/8:jessie64")
REPO_SYMBOLIC_LINKS+=("templates/Debian/9:stretch64")
REPO_SYMBOLIC_LINKS+=("templates/Debian/10:buster64")

REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/12.04:precise64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/14.04:trusty64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/14.10:utopic64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/15.04:vivid64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/15.10:wily64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/16.04:xenial64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/16.10:yakkety64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/17.04:zesty64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/17.10:artful64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/18.04:bionic64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/18.10:cosmic64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/20.04:focal64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/22.04:jammy64")
REPO_SYMBOLIC_LINKS+=("templates/Ubuntu/24.04:noble64")

#### LOGGING RELATED
LOG_ERROR=0
LOG_WARN=1
LOG_INFO=2
LOG_TRACE=3
LOG_DEBUG=4

#LOG_LEVEL=${LOG_DEBUG}
LOG_LEVEL=${LOG_INFO}

function logError() {
  if [ $LOG_LEVEL -ge $LOG_ERROR ]; then
  	echo -e "[ERROR]: ${1}"
  fi
}
function logWarn() {
  if [ $LOG_LEVEL -ge $LOG_WARN ]; then
  	echo -e "[WARN ]: ${1}"
  fi
}
function logInfo() {
  if [ $LOG_LEVEL -ge $LOG_INFO ]; then
  	echo -e "[INFO ]: ${1}"
  fi
}
function logTrace() {
  if [ $LOG_LEVEL -ge $LOG_TRACE ]; then
  	echo -e "[TRACE]: ${1}"
  fi
}
function logDebug() {
  if [ $LOG_LEVEL -ge $LOG_DEBUG ]; then
  	echo -e "[DEBUG]: ${1}"
  fi
}

function setLogLevel() {
  local LOGLEVEL=$1

  case "${LOGLEVEL}" in
    ERROR*)
      LOG_LEVEL=$LOG_ERROR
      ;;
    WARN*)
      LOG_LEVEL=$LOG_WARN
      ;;
    INFO*)
      LOG_LEVEL=$LOG_INFO
      ;;
    TRACE*)
      LOG_LEVEL=$LOG_TRACE
      ;;
    DEBUG*)
      LOG_LEVEL=$LOG_DEBUG
      ;;
    *)
      abort "Unknown loglevel of [${LOGLEVEL}] specified"
  esac

}


## ref: https://unix.stackexchange.com/questions/573047/how-to-get-the-relative-path-between-two-directories
function get_rel_path() {
  ## get the relative path between two directories
  set -- "${1%/}/" "${2%/}/" ''               ## '/'-end to avoid mismatch
  while [ "$1" ] && [ "$2" = "${2#"$1"}" ]    ## reduce $1 to shared path
  do  set -- "${1%/?*/}/"  "$2" "../$3"       ## source/.. target ../relpath
  done
  REPLY="${3}${2#"$1"}"                       ## build result
  # unless root chomp trailing '/', replace '' with '.'
  [ "${REPLY#/}" ] && REPLY="${REPLY%/}" || REPLY="${REPLY:-.}"
  echo "${REPLY}"
}


#############################
##
## `REPO_SYMBOLIC_LINKS` uses the following dictionary format to specify any special links:
##
##   LINK_DEST:LINK_SOURCE[:USE_REL_PATH]
##
## examples:
## REPO_SYMBOLIC_LINKS=("${ROLE_PATH}/vars/update_inventory/update_groups:../update_groups")
## REPO_SYMBOLIC_LINKS+=("${ROLE_PATH}/vars/update_inventory/update_hosts:../update_hosts")
## REPO_SYMBOLIC_LINKS+=("${ROLE_PATH}/templates/update_inventory/update_groups:${ROLE_PATH}/vars/update_groups":1)
## REPO_SYMBOLIC_LINKS+=("${ROLE_PATH}/templates/update_inventory/update_hosts:${ROLE_PATH}/vars/update_hosts":1)
##
## The `create_repo_symbolic_links` function will automatically create symbolic links defined in REPO_SYMBOLIC_LINKS
## Set USE_REL_PATH=1 for the function to calculate/set the link to the relative path from the LINK_SOURCE to the LINK_DEST
##
function create_repo_symbolic_links() {
  local BASE_DIRECTORY=$1
  shift 1
  local REPO_SYMBOLIC_LINKS=("$@")

  local LOG_PREFIX="==> create_repo_symbolic_links():"

  logDebug "${LOG_PREFIX} BASE_DIRECTORY=${BASE_DIRECTORY}"

  logInfo "${LOG_PREFIX} removing existing links"
  DELETE_EXISTING_LINKS_CMD="find ${BASE_DIRECTORY}/templates -type l -print -delete > /dev/null 2>&1"
  logInfo "${LOG_PREFIX} ${DELETE_EXISTING_LINKS_CMD}"
  eval "${DELETE_EXISTING_LINKS_CMD}"

  ##
  ## for each PATH iteration create a soft link back to all files found in the respective base directory (Sandbox/Prod)
  ##
  IFS=$'\n'
  for SYMLINK_INFO in "${REPO_SYMBOLIC_LINKS[@]}"
  do

    logDebug "${LOG_PREFIX} Create REPO_SYMBOLIC_LINKS symlinks for SYMLINK_INFO [$SYMLINK_INFO]"
    # split sub-list if available
    if [[ "${SYMLINK_INFO}" != *":"* ]]; then
      ## continue to next item
      break
    fi

    # ref: https://stackoverflow.com/questions/12317483/array-of-arrays-in-bash
    # split server name from sub-list
#      LINK_INFO_ARRAY=(${SYMLINK_INFO//:/})
    IFS=":" read -a LINK_INFO_ARRAY <<< $SYMLINK_INFO
    LINK_DEST=${LINK_INFO_ARRAY[0]}
    LINK_SOURCE=${LINK_INFO_ARRAY[1]}
    USE_REL_PATH=${LINK_INFO_ARRAY[2]:-0}

    logDebug "${LOG_PREFIX} LINK_DEST=[$LINK_DEST]"
    logDebug "${LOG_PREFIX} LINK_SOURCE=[$LINK_SOURCE]"
    logDebug "${LOG_PREFIX} USE_REL_PATH=[$USE_REL_PATH]"

    LINK_NAME=$(basename "${LINK_DEST}")
    logDebug "${LOG_PREFIX} LINK_NAME=[$LINK_NAME]"

    LINK_REL_DIR=$(dirname "${LINK_DEST}")
    logDebug "${LOG_PREFIX} LINK_REL_DIR=${LINK_REL_DIR}"

    LINK_DIR="${BASE_DIRECTORY}/${LINK_REL_DIR}"
    logDebug "${LOG_PREFIX} LINK_DIR=${LINK_DIR}"

    logDebug "${LOG_PREFIX} cd ${LINK_DIR}"
    cd "${LINK_DIR}"/

    if [ "${USE_REL_PATH}" -eq 1 ]; then
      LINK_SOURCE_NAME=$(basename "${LINK_SOURCE}")
      if [[ "${LINK_SOURCE}" == "/"* ]]; then
        LINK_SOURCE_DIR=$(dirname "${LINK_SOURCE}")
      else
        LINK_SOURCE_DIR="${BASE_DIRECTORY}/$(dirname "${LINK_SOURCE}")"
      fi

      logDebug "${LOG_PREFIX} LINK_SOURCE_DIR=${LINK_SOURCE_DIR}"
      logDebug "${LOG_PREFIX} LINK_SOURCE_NAME=${LINK_SOURCE_NAME}"

      logDebug "${LOG_PREFIX} get relative path between $PWD and $LINK_SOURCE_DIR dirs"
      REL_PATH=$(get_rel_path "$PWD" "$LINK_SOURCE_DIR")
      logDebug "${LOG_PREFIX} REL_PATH=${REL_PATH}"
      LINK_SOURCE="${REL_PATH}/${LINK_SOURCE_NAME}"
      logDebug "${LOG_PREFIX} RELATIVE LINK_SOURCE=${LINK_SOURCE}"
    fi

    if [[ -e "${LINK_SOURCE}" ]]; then
      LINK_CMD="ln -sf ${LINK_SOURCE} ${LINK_NAME}"
      logInfo "${LOG_PREFIX} [${LINK_REL_DIR}]: ${LINK_CMD}"
      eval "${LINK_CMD}"
    else
      logError "${LOG_PREFIX} path not found for LINK_SOURCE=[${LINK_SOURCE}], skipping..."
    fi

  done

  return 0
}


function usage() {
  echo "Usage: ${0} [options]"
  echo ""
  echo "  Options:"
  echo "       -L [ERROR|WARN|INFO|TRACE|DEBUG] : run with specified log level (default INFO)"
  echo "       -v : show script version"
  echo "       -h : help"
  echo ""
  echo "  Examples:"
	echo "       ${0} "
	echo "       ${0} -L DEBUG"
  echo "       ${0} -v"
	[ -z "$1" ] || exit "$1"
}

function main() {

  logInfo "==> PROJECT_DIR=${PROJECT_DIR}"

  while getopts "L:pvh" opt; do
      case "${opt}" in
          L) setLogLevel "${OPTARG}" ;;
          v) echo "${VERSION}" && exit ;;
          h) usage 1 ;;
          \?) usage 2 ;;
          *) usage ;;
      esac
  done
  shift $((OPTIND-1))

  create_repo_symbolic_links "${PROJECT_DIR}" "${REPO_SYMBOLIC_LINKS[@]}"
}

main "$@"
