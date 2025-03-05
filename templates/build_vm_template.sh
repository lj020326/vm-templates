#!/usr/bin/env bash

VERSION="2025.2.10"

BUILD_TAG="$( basename "${0}" )-test"
BUILD_ID="$( basename "${0}" )-test"
BUILD_URL="$( basename "${0}" )-test"
#BUILD_ID="${0}-test"
GIT_COMMIT="$(git rev-parse HEAD)"

PACKER_DEBUG=0
#PACKER_DEBUG=1
PACKER_LOG=1
#PACKER_ON_ERROR=abort
PACKER_ON_ERROR=ask
PACKER_FORCE_BUILD=1
PACKER_FORMAT="hcl"
#PACKER_FORMAT="json"

#SYNC_JSON2HCL=1
SYNC_JSON2HCL=0

if [[ "${PACKER_FORMAT}" == "json" ]]; then
  PACKER_VAR_FORMAT="json"
  PACKER_BUILD_FORMAT="json"
elif [[ "${PACKER_FORMAT}" == "hcl" ]]; then
  PACKER_VAR_FORMAT="json.pkrvars.hcl"
  PACKER_BUILD_FORMAT="json.pkr.hcl"
fi


PACKER_ENV_VARS="
VMWARE_VCENTER_PASSWORD
VMWARE_ESXI_PASSWORD
PACKER_USER_USERNAME
PACKER_USER_PASSWORD
"

#VM_DIST_LIST_DEFAULT="
#Debian,9,debian-9.13.0-amd64-netinst.iso
#CentOS,8,CentOS-8.5.2111-x86_64-dvd1.iso
#CentOS,8-stream,CentOS-Stream-8-x86_64-latest-dvd1.iso
#"

#VM_DIST_LIST_DEFAULT="
#Ubuntu,24.04,ubuntu24.04.iso
#"

VM_DIST_LIST_DEFAULT=("Ubuntu,24.04")

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

function get_build_vm_template_command() {
  local PACKER_COMMAND=$1
  local VM_DIST=$2
  local VM_DIST_VERSION=$3
  local VM_TEMPLATE_BUILD_TYPE=$4
  local VM_DIST_ISO=$5
  local VM_BUILDER=${6:-vsphere-iso}

  ## ref: https://stackoverflow.com/questions/15870480/how-to-convert-a-date-time-string-to-an-integer-in-bash-shell
#  RUN_ID=$(date "+%s%N" | cut -b1-13)
  RUN_ID="test"

  VM_NAME=vm-template-${VM_DIST}-${VM_DIST_VERSION}-${RUN_ID}
  VM_DIST_DIR="${VM_DIST}"
  VM_DIST_VERSION_DIR="${VM_DIST_DIR}/${VM_DIST_VERSION}"
  VM_BUILD_ENV="prod"

  VAULTPASS_FILEPATH="${HOME}/.vault_pass"
  if [[ -f "${PROJECT_DIR}/.vault_pass" ]]; then
    VAULTPASS_FILEPATH="${PROJECT_DIR}/.vault_pass"
  fi

  ###########################################################
  ## DO NOT REMOVE :
  ##   ENV var required in common-vars.json
  export ANSIBLE_VAULT_PASSWORD=$(<"${VAULTPASS_FILEPATH}")

  BUILD_CONFIG="${VM_DIST_DIR}/"
  if [[ "${PACKER_FORMAT}" == "json" ]]; then
#  BUILD_CONFIG=${PROJECT_DIR}/templates/${VM_DIST_DIR}/build-config.json
    BUILD_CONFIG="${VM_DIST_DIR}/build-config.${PACKER_BUILD_FORMAT}"
  fi

  ## ref: https://stackoverflow.com/questions/34521084/command-for-debugging-and-log-packer-build-in-windows
  PACKER_CMD_ARRAY=("env PACKER_LOG=${PACKER_LOG}")
  PACKER_CMD_ARRAY+=("BUILD_TAG=${BUILD_TAG}")
  PACKER_CMD_ARRAY+=("BUILD_ID=${BUILD_ID}")
  PACKER_CMD_ARRAY+=("BUILD_URL=${BUILD_URL}")
  PACKER_CMD_ARRAY+=("GIT_COMMIT=${GIT_COMMIT}")
  if [[ "${PACKER_FORMAT}" == "json" ]]; then
    PACKER_CMD_ARRAY+=("packer ${PACKER_COMMAND} -only ${VM_BUILDER}")
  else
    PACKER_CMD_ARRAY+=("packer ${PACKER_COMMAND} -only ${VM_BUILDER}.${VM_DIST}")
  fi
  if [[ "${PACKER_COMMAND}" == "build" ]]; then
    PACKER_CMD_ARRAY+=("-on-error=${PACKER_ON_ERROR}")
  fi
  if [[ "${PACKER_VAR_FORMAT}" == "json" ]]; then
    PACKER_CMD_ARRAY+=("-var-file=common-vars.${PACKER_VAR_FORMAT}")
  fi
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_DIR}/env-vars.${VM_BUILD_ENV}.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_DIR}/distribution-vars.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_VERSION_DIR}/server/template.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_VERSION_DIR}/server/box_info.${VM_TEMPLATE_BUILD_TYPE}.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var vm_template_build_name=${VM_NAME}")
  PACKER_CMD_ARRAY+=("-var vm_template_build_type=${VM_TEMPLATE_BUILD_TYPE}")
  PACKER_CMD_ARRAY+=("-var vm_template_name=${VM_NAME}")
  PACKER_CMD_ARRAY+=("-var vm_build_env=${VM_BUILD_ENV}")
  PACKER_CMD_ARRAY+=("-var iso_dir=${VM_DIST_VERSION_DIR}")
  PACKER_CMD_ARRAY+=("-var iso_file=${VM_DIST_ISO}")
  if [[ ${PACKER_FORCE_BUILD} -ne 0 ]]; then
    if [[ "${PACKER_COMMAND}" == "build" ]]; then
      PACKER_CMD_ARRAY+=("-force")
    fi
  fi
  if [[ ${PACKER_DEBUG} -ne 0 ]]; then
    PACKER_CMD_ARRAY+=("-debug")
  fi
  PACKER_CMD_ARRAY+=("${BUILD_CONFIG}")

  ## ref: https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-a-bash-array-into-a-delimited-string
  local PACKER_CMD=$(printf " %s" "${PACKER_CMD_ARRAY[@]}")

  echo "${PACKER_CMD}"
}

function validate_vm_template() {
  local PACKER_COMMAND_ARGS=("validate")
  PACKER_COMMAND_ARGS+=("$@")
  logInfo "PACKER_COMMAND_ARGS=${PACKER_COMMAND_ARGS[@]}"

  local PACKER_CMD=$(get_build_vm_template_command "${PACKER_COMMAND_ARGS[@]}")

  handle_cmd_return_code "${PACKER_CMD}"
  logInfo "SUCCESS => No exceptions found from packer validate"
}

function build_vm_template() {
  local PACKER_COMMAND_ARGS=("build")
  PACKER_COMMAND_ARGS+=("$@")
  logInfo "PACKER_COMMAND_ARGS=${PACKER_COMMAND_ARGS[@]}"

  local PACKER_CMD=$(get_build_vm_template_command "${PACKER_COMMAND_ARGS[@]}")

  handle_cmd_return_code "${PACKER_CMD}"
  logInfo "SUCCESS => No exceptions found from packer build"
}

function validate_env_vars() {

  MISSING_ENV_VARS=()

  IFS=$'\n'
  for VAR_NAME in ${PACKER_ENV_VARS}
  do
    logInfo "checking if env var [${VAR_NAME}] exists"
    ## ref: https://stackoverflow.com/questions/2634590/using-a-variable-to-refer-to-another-variable-in-bash
    if [[ -z "${!VAR_NAME}" ]]; then
      MISSING_ENV_VARS+=("${VAR_NAME}")
    fi
  done

#  logInfo "MISSING_ENV_VARS=${MISSING_ENV_VARS[@]}"
  MISSING_ENV_VARS_LENGTH=${#MISSING_ENV_VARS[@]}

  if [[ ${MISSING_ENV_VARS_LENGTH} -gt 0 ]]; then
    logError "The following ENV VARS are required but missing:"
    logError "${MISSING_ENV_VARS[@]}"
    exit 1
  fi

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

  cd "${PROJECT_DIR}/templates"
  if [[ ${SYNC_JSON2HCL} -ne 0 ]]; then
    logInfo "Synchronize json config to HCL2"
  #  ./convert_json2hcl.sh "${VM_DIST_LIST}"
    ./config.sh "${VM_DIST_LIST}"
  fi

  logInfo "Validate all necessary env vars exist"
  validate_env_vars

  IFS=$'\n'
  for VM_DIST_INFO in "${VM_DIST_LIST[@]}"
  do

    logInfo "*******************************"

    logInfo "Create vm template for VM_DIST_INFO [$VM_DIST_INFO]"
    # split sub-list if available
    if [[ $VM_DIST_INFO == *","* ]]
    then
      # ref: https://stackoverflow.com/questions/12317483/array-of-arrays-in-bash
      # split server name from sub-list
      IFS="," read -a DIST_INFO_ARRAY <<< $VM_DIST_INFO
      VM_DIST="${DIST_INFO_ARRAY[0]}"
      VM_DIST_VERSION="${DIST_INFO_ARRAY[1]}"
      VM_TEMPLATE_BUILD_TYPE="${DIST_INFO_ARRAY[2]-"small"}"
#      VM_DIST_ISO="${DIST_INFO_ARRAY[3]}"
      VM_DIST_ISO="${DIST_INFO_ARRAY[3]-"${VM_DIST}.${VM_DIST_VERSION}.iso"}"

      logInfo "VM_DIST=[$VM_DIST]"
      logInfo "VM_DIST_VERSION=[$VM_DIST_VERSION]"
      logInfo "VM_DIST_ISO=[$VM_DIST_ISO]"

      logInfo "Validate packer build"
      validate_vm_template "${VM_DIST}" "${VM_DIST_VERSION}" "${VM_TEMPLATE_BUILD_TYPE}" "${VM_DIST_ISO}"

  #    logInfo "Run packer build"
  #    build_vm_template "${VM_DIST}" "${VM_DIST_VERSION}" "${VM_DIST_ISO}"

    fi

  done

}

main "$@"
