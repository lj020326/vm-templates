#!/usr/bin/env bash

VERSION="2025.2.10"

VM_DIST_LIST_DEFAULT=()
VM_DIST_LIST_DEFAULT+=("CentOS,8")
VM_DIST_LIST_DEFAULT+=("CentOS,9")
VM_DIST_LIST_DEFAULT+=("CentOS,10")
VM_DIST_LIST_DEFAULT+=("Debian,10")
VM_DIST_LIST_DEFAULT+=("Debian,11")
VM_DIST_LIST_DEFAULT+=("Debian,12")
VM_DIST_LIST_DEFAULT+=("RHEL,8")
VM_DIST_LIST_DEFAULT+=("RHEL,9")
VM_DIST_LIST_DEFAULT+=("Ubuntu,20.04")
VM_DIST_LIST_DEFAULT+=("Ubuntu,22.04")
VM_DIST_LIST_DEFAULT+=("Ubuntu,24.04")
VM_DIST_LIST_DEFAULT+=("Windows/server,2016")
VM_DIST_LIST_DEFAULT+=("Windows/server,2019")
VM_DIST_LIST_DEFAULT+=("Windows/server,2022")
VM_DIST_LIST_DEFAULT+=("Windows/desktop,10")
VM_DIST_LIST_DEFAULT+=("Windows/desktop,11")

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
#  	echo -e "[ERROR]: ==> ${1}"
  	logMessage "${LOG_ERROR}" "${1}"
  fi
}
function logWarn() {
  if [ $LOG_LEVEL -ge $LOG_WARN ]; then
#  	echo -e "[WARN ]: ==> ${1}"
  	logMessage "${LOG_WARN}" "${1}"
  fi
}
function logInfo() {
  if [ $LOG_LEVEL -ge $LOG_INFO ]; then
#  	echo -e "[INFO ]: ==> ${1}"
  	logMessage "${LOG_INFO}" "${1}"
  fi
}
function logTrace() {
  if [ $LOG_LEVEL -ge $LOG_TRACE ]; then
#  	echo -e "[TRACE]: ==> ${1}"
  	logMessage "${LOG_TRACE}" "${1}"
  fi
}
function logDebug() {
  if [ $LOG_LEVEL -ge $LOG_DEBUG ]; then
#  	echo -e "[DEBUG]: ==> ${1}"
  	logMessage "${LOG_DEBUG}" "${1}"
  fi
}

function logMessage() {
  local LOG_MESSAGE_LEVEL="${1}"
  local LOG_MESSAGE="${2}"
  ## remove first item from FUNCNAME array
#  local CALLING_FUNCTION_ARRAY=("${FUNCNAME[@]:2}")
  ## Get the length of the array
  local CALLING_FUNCTION_ARRAY_LENGTH=${#FUNCNAME[@]}
  local CALLING_FUNCTION_ARRAY=("${FUNCNAME[@]:2:$((CALLING_FUNCTION_ARRAY_LENGTH - 3))}")
#  echo "CALLING_FUNCTION_ARRAY[@]=${CALLING_FUNCTION_ARRAY[@]}"

  local CALL_ARRAY_LENGTH=${#CALLING_FUNCTION_ARRAY[@]}
  local REVERSED_CALL_ARRAY=()
  for (( i = CALL_ARRAY_LENGTH - 1; i >= 0; i-- )); do
    REVERSED_CALL_ARRAY+=( "${CALLING_FUNCTION_ARRAY[i]}" )
  done
#  echo "REVERSED_CALL_ARRAY[@]=${REVERSED_CALL_ARRAY[@]}"

#  local CALLING_FUNCTION_STR="${CALLING_FUNCTION_ARRAY[*]}"
  ## ref: https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-a-bash-array-into-a-delimited-string#17841619
  local SEPARATOR=":"
  local CALLING_FUNCTION_STR=$(printf "${SEPARATOR}%s" "${REVERSED_CALL_ARRAY[@]}")
  local CALLING_FUNCTION_STR=${CALLING_FUNCTION_STR:${#SEPARATOR}}

  case "${LOG_MESSAGE_LEVEL}" in
    $LOG_ERROR*)
      LOG_LEVEL_STR="ERROR"
      ;;
    $LOG_WARN*)
      LOG_LEVEL_STR="WARN"
      ;;
    $LOG_INFO*)
      LOG_LEVEL_STR="INFO"
      ;;
    $LOG_TRACE*)
      LOG_LEVEL_STR="TRACE"
      ;;
    $LOG_DEBUG*)
      LOG_LEVEL_STR="DEBUG"
      ;;
    *)
      abort "Unknown LOG_MESSAGE_LEVEL of [${LOG_MESSAGE_LEVEL}] specified"
  esac

  local LOG_LEVEL_PADDING_LENGTH=5
  local PADDED_LOG_LEVEL=$(printf "%-${LOG_LEVEL_PADDING_LENGTH}s" "${LOG_LEVEL_STR}")

  local LOG_PREFIX="${CALLING_FUNCTION_STR}():"
  echo -e "[${PADDED_LOG_LEVEL}]: ==> ${LOG_PREFIX} ${LOG_MESSAGE}"
}

function setLogLevel() {
  LOG_LEVEL_STR=$1

  case "${LOG_LEVEL_STR}" in
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
      DISPLAY_TEST_RESULTS=1
      ;;
    *)
      abort "Unknown LOG_LEVEL_STR of [${LOG_LEVEL_STR}] specified"
  esac

}

function handle_cmd_return_code() {
  local RUN_COMMAND=$1

  logInfo "${RUN_COMMAND}"
  COMMAND_RESULT=$(eval "${RUN_COMMAND} 2>&1")
#  COMMAND_RESULT=$(eval "${RUN_COMMAND} > /dev/null 2>&1")
  local RETURN_STATUS=$?

  if [[ $RETURN_STATUS -eq 0 ]]; then
    logDebug "${COMMAND_RESULT}"
    logDebug "SUCCESS!"
  else
    logError "ERROR (${RETURN_STATUS})"
    echo "${COMMAND_RESULT}"
    exit 1
  fi

}

function handle_cmd_return_code_orig() {
  local RUN_COMMAND=$1

  logInfo "${RUN_COMMAND}"
  eval "${RUN_COMMAND} > /dev/null 2>&1"
  local RETURN_STATUS=$?

  if [[ $RETURN_STATUS -eq 0 ]]; then
    logDebug "SUCCESS => No exceptions found from packer validate!!"
  else
    logError "packer validate resulted in return code [${RETURN_STATUS}]!! :("
    logError "${RUN_COMMAND}"
    eval "${RUN_COMMAND}"
    exit 1
  fi

}

## ref: https://unix.stackexchange.com/questions/573047/how-to-get-the-relative-path-between-two-directories
function pnrelpath() {
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

function convert_json2hcl() {

  JSON_FILE=$1
  FILE_TYPE=${2:-"vars"}
  BUILD_DIST=${3:-$(dirname "${JSON_FILE}")}

  JSON_SOURCE_FILE="${JSON_FILE}"

  logDebug "BUILD_DIST=${BUILD_DIST}"

  if [[ ${BACKUP_HCL_FILES} -ne 0 ]]; then
    if [ -e "${HCL2_FILE}" ]; then
      logDebug "backup existing ${HCL2_FILE}"
      mv "${HCL2_FILE}" "${HCL2_FILE}.${TIMESTAMP}~"
    fi
  fi

  HCL2_FILE_FORMAT="pkr.${HCL2_FORMAT}"
#  if [[ "${FILE_TYPE}" == "vardef" ]]; then
#    HCL2_FILE_FORMAT="pkr.hcl"
#    ## ref: https://stackoverflow.com/questions/48470049/build-a-json-string-with-bash-variables
#    #logDebug "create empty variables json"
#    #VARS_JSON=$(jq -n '{variables: {} }')
#    #logDebug "VARS_JSON=${VARS_JSON}"
#
#    JSON_SOURCE_FILE="${TEMP_DIR}/$(basename ${JSON_FILE})"
#
#    ## ref: https://unix.stackexchange.com/questions/460985/jq-add-objects-from-file-into-json-array
#    ## ref: https://stackoverflow.com/questions/38860529/create-json-using-jq-from-pipe-separated-keys-and-values-in-bash
#    if [[ "${FILE_TYPE}" == "vardef" ]]; then
#      logDebug "Create variable definition vars json file at [${JSON_SOURCE_FILE}]"
#      jq --argjson varInfo "$(<${JSON_FILE})" '.variables += $varInfo' -n '{variables: $varInfo }' > "${JSON_SOURCE_FILE}"
#    fi
#  elif [[ "${FILE_TYPE}" == "vars" ]]; then
  if [[ "${FILE_TYPE}" == "vars" ]]; then
    ### ref: https://www.virtualizationhowto.com/2022/06/convert-packer-variables-json-to-hcl2-for-automated-vsphere-builds/
    ##HCL2_FILE_FORMAT="pkrvars.hcl"
    ### ref: https://developer.hashicorp.com/packer/guides/hcl/variables
    ## HCL2_FILE_FORMAT="vars.hcl"
    HCL2_FILE_FORMAT="pkrvars.${HCL2_FORMAT}"
  fi

  HCL2_FILE="${JSON_FILE}.${HCL2_FILE_FORMAT}"

  if [[ "${FILE_TYPE}" == "vars" ]]; then
    logDebug "Create variable block vars json file at [${JSON_SOURCE_FILE}]"
    ## ref: https://stackoverflow.com/questions/66564551/convert-json-to-simple-key-value-file-using-jq
    ## ref: https://stackoverflow.com/questions/25378013/how-to-convert-a-json-object-to-key-value-format-in-jq
    ## preserve escape character '\'
    jq -r 'to_entries[] | (.key) + "=\"" + .value +"\""' < "${JSON_FILE}" | sed 's/\\/\\\\/' > "${HCL2_FILE}"
  else
    logDebug "Convert [${JSON_SOURCE_FILE}] to [${HCL2_FILE}]"
    PACKER_CONVERT_CMD="packer hcl2_upgrade -output-file=${HCL2_FILE} -with-annotations ${JSON_SOURCE_FILE}"
    logInfo "${PACKER_CONVERT_CMD}"
    handle_cmd_return_code "${PACKER_CONVERT_CMD}"
  fi

  if [[ "${FILE_TYPE}" == "build" ]]; then
    BUILD_PLATFORM=$(echo "${BUILD_DIST}" | cut -d/ -f1)
    logDebug "Convert autogenerated_* pattern to platform [${BUILD_PLATFORM}]"
    "${SED_CMD}" -i 's|autogenerated_\([0-9]\+\)|'"${BUILD_PLATFORM}"'|g' "${HCL2_FILE}"
  fi

#    logDebug "Convert templatefile pattern"
##    "${SED_CMD}" -i 's|"{{ templatefile($\(.*\),\(.*\)) }}"|templatefile\("\1",\2\)|g' "${HCL2_FILE}"
#    "${SED_CMD}" -i 's|"templatefile(\(.*\), $\(.*\))"|templatefile\("\1", "\2"\)|g' "${HCL2_FILE}"

  logDebug "Convert \$$ to $ in ${HCL2_FILE}"
  "${SED_CMD}" -i 's|\$\$|\$|g' "${HCL2_FILE}"

  logDebug "Convert \\\" to \" in ${HCL2_FILE}"
  "${SED_CMD}" -i 's|\\\"|\"|g' "${HCL2_FILE}"

  logDebug "Convert template function patterns (prefixed with %%) in ${HCL2_FILE}"
##    "${SED_CMD}" -i 's|"%%\(.*\)(\(.*\), $\(.*\))"|\1\("\2", "\3"\)|g' "${HCL2_FILE}"
#    "${SED_CMD}" -i 's|"%%\(.*\)(\(.*\), \(.*\))"|\1\("\2", "\3"\)|g' "${HCL2_FILE}"

#  "${SED_CMD}" -i 's|"%%\(.*\)(\(.*\))"|\1\(\2\)|g' "${HCL2_FILE}"
  "${SED_CMD}" -i 's|"%%\(.*\)"|\1|g' "${HCL2_FILE}"

}

function convert_dist2hcl() {
  local VM_DIST_INFO=$1

  # ref: https://stackoverflow.com/questions/12317483/array-of-arrays-in-bash
  # split server name from sub-list
  IFS="," read -a DIST_INFO_ARRAY <<< $VM_DIST_INFO
  local VM_DIST=${DIST_INFO_ARRAY[0]}
  local VM_DIST_VERSION=${DIST_INFO_ARRAY[1]}

  logDebug "**************************************"
  logDebug "DIST_INFO_ARRAY LENGTH=${#DIST_INFO_ARRAY[@]}"

#  if [ ${#DIST_INFO_ARRAY[@]} -gt 2 ]; then
#    VM_DIST_VERSION+="/${DIST_INFO_ARRAY[2]}"
#  fi
  local VM_DIST_DIR="${VM_DIST}"
  local VM_DIST_VERSION_DIR="${VM_DIST_DIR}/${VM_DIST_VERSION}"

  logDebug "VM_DIST=[$VM_DIST]"
  logDebug "VM_DIST_VERSION=[$VM_DIST_VERSION]"

#  COMMON_VARS_FILE_HCL="${COMMON_VARS_FILE_JSON}.pkr.hcl"
#  if [[ ! -e "${VM_DIST_DIR}/${COMMON_VARS_FILE_HCL}" ]]; then
#    logDebug "Create symbolic link to ${COMMON_VARS_FILE_HCL}"
#    cd "${VM_DIST_DIR}"
#    ln -sf "../${COMMON_VARS_FILE_HCL}" .
#    cd ../
#  fi

  local TEMPLATE_BASE_DIRECTORY=$PWD

  logDebug "BASE_DIRECTORY=$TEMPLATE_BASE_DIRECTORY"

#  local COMMON_VARS_FILE_HCL_LIST=$(find "${TEMPLATE_DIR}/" -maxdepth 1 -type f -wholename "*.pkr.hcl" | sort)
  local COMMON_VARS_FILE_HCL_LIST=$(find "${TEMPLATE_DIR}/" -maxdepth 1 -type f -wholename "*.hcl" | sort)
  logDebug "COMMON_VARS_FILE_HCL_LIST=[$COMMON_VARS_FILE_HCL_LIST]"

  logInfo "Link common var HCL files into each VM_DIST_DIR"
  IFS=$'\n'
  for COMMON_VAR_HCL_FILE in ${COMMON_VARS_FILE_HCL_LIST}
  do
    logDebug "Link hcl2 var file [${COMMON_VAR_HCL_FILE}] to VM_DIST_DIR [$VM_DIST_DIR]"
    logDebug "pwd=`pwd`"
    cd "${VM_DIST_DIR}"
    RELPATH=$(pnrelpath "$PWD" "$TEMPLATE_BASE_DIRECTORY")
    logDebug "RELPATH=${RELPATH}"

    ln -sf "${RELPATH}/$(basename ${COMMON_VAR_HCL_FILE})" .
#    ln -sf "../$(basename ${COMMON_VAR_HCL_FILE})" .
#    cd ../
    cd "${TEMPLATE_BASE_DIRECTORY}"
  done

  DIST_VAR_FILE_LIST=$(\
    (find "${VM_DIST_DIR}/" -type f -wholename "*/distribution-vars.json" &&
    find "${VM_DIST_VERSION_DIR}/" -type f -wholename "*/box_info.*json" &&
    find "${VM_DIST_VERSION_DIR}/" -type f -wholename "*/template.json") \
    | sort)

#  local DIST_VARS_FILE_JSON="${VM_DIST_DIR}/distribution-vars.json"
#  local DIST_BOX_VARS_FILE_JSON="${VM_DIST_VERSION_DIR}/box_info.json"
#  local DIST_TEMPLATE_VARS_FILE_JSON="${VM_DIST_VERSION_DIR}/template.json"
  local DIST_BUILD_FILE_JSON="${VM_DIST_DIR}/build-config.json"

  logInfo "Convert each dist var file"
  IFS=$'\n'
  for DIST_VAR_FILE in ${DIST_VAR_FILE_LIST}
  do
    if [ -e "${DIST_VAR_FILE}" ]; then
      logDebug "Convert ${DIST_VAR_FILE}"
#      convert_json2hcl "${DIST_VAR_FILE}"
      handle_cmd_return_code "convert_json2hcl ${DIST_VAR_FILE}"
    fi
  done

  logDebug "Convert ${DIST_BUILD_FILE_JSON}"
#  convert_json2hcl "${DIST_BUILD_FILE_JSON}" "build"
#  PACKER_CONVERT_CMD="convert_json2hcl ${DIST_BUILD_FILE_JSON} build"
#  handle_cmd_return_code "${PACKER_CONVERT_CMD}"
  handle_cmd_return_code "convert_json2hcl ${DIST_BUILD_FILE_JSON} build"
}


function usage() {
  echo "Usage: ${0} [options] [[VM_DIST_INFO1] [VM_DIST_INFO2] ...]"
  echo ""
  echo "       VM_DIST_INFO[n] is a comma delimited tuple with VM_DIST,VM_DIST_VERSION[,VM_TEMPLATE_BUILD_TYPE,VM_DIST_ISO]"
  echo ""
  echo "       - VM_TEMPLATE_BUILD_TYPE defaults to 'small'"
  echo "       - VM_DIST_ISO defaults to \${VM_DIST}.\${VM_DIST_VERSION}.iso"
  echo ""
  echo "  Options:"
  echo "       -L [ERROR|WARN|INFO|TRACE|DEBUG] : run with specified log level (default INFO)"
  echo "       -v : show script version"
  echo "       -h : help"
  echo ""
  echo "  Examples:"
	echo "       ${0} "
	echo "       ${0} Ubuntu,24.04"
	echo "       ${0} Ubuntu,24.04,small"
	echo "       ${0} Ubuntu,24.04,small,Ubuntu.2404.iso"
	echo "       ${0} -L DEBUG CentOS,9"
	echo "       ${0} Debian,8 Ubuntu,22.04 CentOS,8"
  echo "       ${0} -v"
	[ -z "$1" ] || exit "$1"
}


function main() {

  while getopts "L:vh" opt; do
      case "${opt}" in
          L) setLogLevel "${OPTARG}" ;;
          v) echo "${VERSION}" && exit ;;
          h) usage 1 ;;
          \?) usage 2 ;;
          *) usage ;;
      esac
  done
  shift $((OPTIND-1))

  local VM_DIST_LIST=("${VM_DIST_LIST_DEFAULT[@]}")
  if [ $# -gt 0 ]; then
    VM_DIST_LIST=("$@")
  fi

  logInfo "VM_DIST_LIST=${VM_DIST_LIST[*]}"

  local PROJECT_DIR=$( git rev-parse --show-toplevel )
  local TEMPLATE_DIR="${PROJECT_DIR}/templates"

  HCL2_FORMAT="hcl"

  ## ref: https://stackoverflow.com/questions/10982911/creating-temporary-files-in-bash
  TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
  TIMESTAMP=$(date +%Y%m%d%H%M%S)
  #BACKUP_HCL_FILES=1
  BACKUP_HCL_FILES=0

  SED_CMD=sed
  # Mac OSX's GNU sed is installed as gsed
  # use e.g. homebrew 'gnu-sed' to get it
  if ! sed --version >/dev/null 2>&1; then
    if gsed --version >/dev/null 2>&1; then
      SED_CMD=gsed
    else
      logError "Error, can't find an acceptable GNU sed." >&2
      exit 1
    fi
  fi

  cd "${TEMPLATE_DIR}"

  COMMON_VARS_FILE="common-vars"
  COMMON_VARS_FILE_JSON="${COMMON_VARS_FILE}.json"

  logInfo "Convert ${COMMON_VARS_FILE_JSON}"
  convert_json2hcl "${COMMON_VARS_FILE_JSON}" "vardef"

  ENV_VAR_FILE_LIST=$(find . -maxdepth 1 -type f -name "env-vars.*.json" | sort)
  logDebug "ENV_VAR_FILE_LIST=[$ENV_VAR_FILE_LIST]"

  logInfo "Convert env var files"
  IFS=$'\n'
  for ENV_VAR_FILE in ${ENV_VAR_FILE_LIST}
  do
    logDebug "Convert env var json to hcl2"
    logDebug "Convert ${ENV_VAR_FILE}"
    convert_json2hcl "${ENV_VAR_FILE}"
  done

  IFS=$'\n'
  for VM_DIST_INFO in "${VM_DIST_LIST[@]}"
  do

    logInfo "**************************************"
    logInfo "Convert dist var json to hcl2 for VM_DIST_INFO [$VM_DIST_INFO]"
    convert_dist2hcl "${VM_DIST_INFO}"

  done

}

main "$@"
