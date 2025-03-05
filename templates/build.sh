#!/usr/bin/env bash

SCRIPT_FILE=$(basename $0)

BUILD_TAG="${SCRIPT_FILE%.*}-test"
#BUILD_TAG="$( basename "${0}" )-test"
#BUILD_TAG="${0}-test"

PACKER_DEBUG=0
#PACKER_DEBUG=1
#PACKER_LOG=1
PACKER_LOG=0
#PACKER_ON_ERROR=abort
PACKER_ON_ERROR=ask
PACKER_FORCE_BUILD=1
PACKER_FORMAT="hcl"
#PACKER_FORMAT="json"
SYNC_JSON2HCL=1

#VALIDATE_ONLY=0
VALIDATE_ONLY=1
ALWAYS_SHOW_TEST_RESULTS=1

if [[ "${PACKER_FORMAT}" == "json" ]]; then
  PACKER_VAR_FORMAT="json"
  PACKER_BUILD_FORMAT="json"
elif [[ "${PACKER_FORMAT}" == "hcl" ]]; then
  PACKER_VAR_FORMAT="json.pkrvars.hcl"
  PACKER_BUILD_FORMAT="json.pkr.hcl"
fi


REQUIRED_BUILD_ENV_VARS="
VMWARE_VCENTER_USERNAME
VMWARE_VCENTER_PASSWORD
PACKER_USER_USERNAME
PACKER_USER_PASSWORD
ANSIBLE_VAULT_PASSWORD
"

#VM_DIST_LIST_DEFAULT="
#CentOS|8|small|CentOS-8.5.2111-x86_64-dvd1.iso
#RHEL|8|small|rhel-8.8-x86_64-dvd.iso
#RHEL|9|small|rhel-9.2-x86_64-dvd.iso
#Windows|2019|standard|windows-SRV2019.DC.ENU.MAY2021.iso
#Windows|2019|datacenter|windows-SRV2019.DC.ENU.MAY2021.iso
#Windows|2022|standard|windows-SRV2022.LTSC.21H2.Build-20348.1006.iso
#Windows|2022|datacenter|windows-SRV2022.LTSC.21H2.Build-20348.1006.iso
#"

VM_DIST_LIST_DEFAULT="
RHEL|8|medium|rhel-8.8-x86_64-dvd.iso
"

VM_DIST_LIST=${1:-${VM_DIST_LIST_DEFAULT}}
VM_BUILD_ENV="DEV"

PROJECT_DIR=$( git rev-parse --show-toplevel )

function init_vm_template() {
  PACKER_COMMAND="init"
  VM_DIST=$1
  VM_DIST_VERSION=$2
  VM_DIST_FLAVOR=$3
  VM_DIST_ISO=$4
  VM_BUILDER=${5:-vsphere-iso}

#  run_packer_command "${PACKER_COMMAND}" "${VM_DIST}" "${VM_DIST_VERSION}" "${VM_DIST_FLAVOR}" "${VM_DIST_ISO}"

  PACKER_CMD="packer init common-build-vars.pkr.hcl"
  echo "************************************"
  echo "** running command=[${PACKER_CMD}]"
  eval "${PACKER_CMD}"

}

function validate_vm_template() {
  PACKER_COMMAND="validate"
  VM_DIST=$1
  VM_DIST_VERSION=$2
  VM_DIST_FLAVOR=$3
  VM_DIST_ISO=$4
  VM_BUILDER=${5:-vsphere-iso}

  run_packer_command "${PACKER_COMMAND}" "${VM_DIST}" "${VM_DIST_VERSION}" "${VM_DIST_FLAVOR}" "${VM_DIST_ISO}"

}

function build_vm_template() {
  PACKER_COMMAND="build"
  VM_DIST=$1
  VM_DIST_VERSION=$2
  VM_DIST_FLAVOR=$3
  VM_DIST_ISO=$4
  VM_BUILDER=${5:-vsphere-iso}

  run_packer_command "${PACKER_COMMAND}" "${VM_DIST}" "${VM_DIST_VERSION}" "${VM_DIST_FLAVOR}" "${VM_DIST_ISO}"

}

function run_packer_command() {

  PACKER_COMMAND=$1
  VM_DIST=$2
  VM_DIST_VERSION=$3
  VM_DIST_FLAVOR=$4
  VM_DIST_ISO=$5
  VM_BUILDER=${6:-vsphere-iso}

  ## ref: https://stackoverflow.com/questions/15870480/how-to-convert-a-date-time-string-to-an-integer-in-bash-shell
#  RUN_ID=$(date "+%s%N" | cut -b1-13)
  RUN_ID="test"

  VM_NAME="vm-template-${VM_DIST}-${VM_DIST_VERSION}-${VM_DIST_FLAVOR}"
  VM_BUILD_NAME="${VM_NAME}-${RUN_ID}"
  VM_DIST_DIR="${VM_DIST}"
  VM_DIST_VERSION_DIR="${VM_DIST_DIR}/${VM_DIST_VERSION}"

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
  PACKER_CMD_ARRAY=("env")
  if [[ PACKER_LOG -gt 0 ]]; then
    PACKER_CMD_ARRAY=("PACKER_LOG=${PACKER_LOG}")
  fi
  PACKER_CMD_ARRAY+=("BUILD_TAG=${BUILD_TAG}")
  PACKER_CMD_ARRAY+=("packer ${PACKER_COMMAND}")

  if [[ "${PACKER_FORMAT}" == "json" ]]; then
    PACKER_CMD_ARRAY+=("-only ${VM_BUILDER}")
  else
    PACKER_CMD_ARRAY+=("-only ${VM_BUILDER}.*")
  fi

  if [[ "${PACKER_COMMAND}" == "build" ]]; then
    PACKER_CMD_ARRAY+=("-on-error=${PACKER_ON_ERROR}")
  fi

  if [[ "${PACKER_VAR_FORMAT}" == "json" ]]; then
    PACKER_CMD_ARRAY+=("-var-file=common-vars.${PACKER_VAR_FORMAT}")
  fi
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_DIR}/distribution-vars.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_VERSION_DIR}/template.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_VERSION_DIR}/box_info.${VM_DIST_FLAVOR}.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var-file=env-vars.${VM_BUILD_ENV}.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var vm_template_build_name=${VM_BUILD_NAME}")
  PACKER_CMD_ARRAY+=("-var vm_template_build_type=${VM_DIST_FLAVOR}")
  PACKER_CMD_ARRAY+=("-var vm_template_name=${VM_NAME}")
  PACKER_CMD_ARRAY+=("-var vm_build_env=${VM_BUILD_ENV}")
  PACKER_CMD_ARRAY+=("-var iso_dir=${VM_DIST_VERSION_DIR}")
  PACKER_CMD_ARRAY+=("-var iso_file=${VM_DIST_ISO}")
  if [[ "${PACKER_COMMAND}" == "build" ]]; then
    if [[ ${PACKER_FORCE_BUILD} -ne 0 ]]; then
      PACKER_CMD_ARRAY+=("-force")
    fi
  fi
  if [[ ${PACKER_DEBUG} -ne 0 ]]; then
    PACKER_CMD_ARRAY+=("-debug")
  fi
  PACKER_CMD_ARRAY+=("${BUILD_CONFIG}")

  ## ref: https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-a-bash-array-into-a-delimited-string
  PACKER_CMD=$(printf " %s" "${PACKER_CMD_ARRAY[@]}")

  echo "************************************"
  echo "** running command=[${PACKER_CMD}]"
  eval "${PACKER_CMD}"

}

function validate_env_vars() {

  MISSING_ENV_VARS=()
  returnStatus=0

  IFS=$'\n'
  for VAR_NAME in ${REQUIRED_BUILD_ENV_VARS}
  do
    echo "checking if env var [${VAR_NAME}] exists"
    ## ref: https://stackoverflow.com/questions/2634590/using-a-variable-to-refer-to-another-variable-in-bash
    if [[ -z "${!VAR_NAME}" ]]; then
      MISSING_ENV_VARS+=("${VAR_NAME}")
    fi
  done

#  echo "MISSING_ENV_VARS=${MISSING_ENV_VARS[@]}"
  MISSING_ENV_VARS_LENGTH=${#MISSING_ENV_VARS[@]}

  if [[ ${MISSING_ENV_VARS_LENGTH} -gt 0 ]]; then
    echo "The following ENV VARS are required but missing:"
    echo "${MISSING_ENV_VARS[@]}"
#    exit 1
    returnStatus=1
  fi

  return "${returnStatus}"
}

function main() {

  cd "${PROJECT_DIR}/templates"

  echo "*******************************"
  echo "Validate all necessary env vars exist"
#  validate_env_vars
  test_results=$(validate_env_vars)
  returnStatus=$?

  echo "validate_env_vars(): returnStatus=${returnStatus}"

  if [[ $returnStatus -gt 0 || $ALWAYS_SHOW_TEST_RESULTS -gt 0 ]]; then
    echo "==> validate_env_vars(): test_results "
    echo "${test_results}"
    echo "==> validate_env_vars(): ^^^^^^^^^^^^^^^^^^^^^^^ "
    if [[ $returnStatus -gt 0 ]]; then
      exit $returnStatus
    fi
  fi

  echo "*******************************"
  echo "Synchronize json config to HCL2"
  if [[ ${SYNC_JSON2HCL} -ne 0 ]]; then
    ./config.sh "${VM_DIST_LIST}"
  fi

  echo "************************************"
  echo "Initialize packer plugins"
  echo "** running command=[${PACKER_CMD}]"
  PACKER_CMD="packer init common-build-vars.pkr.hcl"
  eval "${PACKER_CMD}"

  echo "*******************************"
  echo "*******************************"
  echo "*******************************"
  echo "*******************************"
  echo "Start building"

  IFS=$'\n'
  for VM_DIST_INFO in ${VM_DIST_LIST}
  do

    echo "Create vm template for VM_DIST_INFO [$VM_DIST_INFO]"
    # split sub-list if available
    if [[ $VM_DIST_INFO == *"|"* ]]
    then
      # ref: https://stackoverflow.com/questions/12317483/array-of-arrays-in-bash
      # split server name from sub-list
      IFS="|" read -a DIST_INFO_ARRAY <<< $VM_DIST_INFO
      VM_DIST="${DIST_INFO_ARRAY[0]}"
      VM_DIST_VERSION="${DIST_INFO_ARRAY[1]}"
      VM_DIST_FLAVOR="${DIST_INFO_ARRAY[2]}"
      VM_DIST_ISO="${DIST_INFO_ARRAY[3]}"

      echo "VM_DIST=[$VM_DIST]"
      echo "VM_DIST_VERSION=[$VM_DIST_VERSION]"
      echo "VM_DIST_FLAVOR=[$VM_DIST_FLAVOR]"
      echo "VM_DIST_ISO=[$VM_DIST_ISO]"

      echo "Run packer validate"
      validate_vm_template "${VM_DIST}" "${VM_DIST_VERSION}" "${VM_DIST_FLAVOR}" "${VM_DIST_ISO}"

      if [[ ${VALIDATE_ONLY} -eq 0 ]]; then
        echo "Run packer build"
        build_vm_template "${VM_DIST}" "${VM_DIST_VERSION}" "${VM_DIST_FLAVOR}" "${VM_DIST_ISO}"
      fi

    fi

  done

  exit 0
}

main
