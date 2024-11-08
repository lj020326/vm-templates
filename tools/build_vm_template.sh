#!/usr/bin/env bash

BUILD_TAG="$( basename "${0}" )-test"
#BUILD_TAG="${0}-test"
BUILD_ENV="PROD"
BUILD_FLAVOR="small"

PACKER_ENV_VARS="
VMWARE_VCENTER_PASSWORD
VMWARE_ESXI_PASSWORD
PACKER_USER_PASSWORD
"

#VM_DIST_LIST="
#Debian|9|debian-9.13.0-amd64-netinst.iso
#CentOS|8|CentOS-8.5.2111-x86_64-dvd1.iso
#CentOS|8-stream|CentOS-Stream-8-x86_64-latest-dvd1.iso
#RHEL|9|rhel-9.2-x86_64-dvd.iso
#"

VM_DIST_LIST="
RHEL|9|rhel-9.2-x86_64-dvd.iso
"

PROJECT_DIR=$( git rev-parse --show-toplevel )
cd "${PROJECT_DIR}/templates"

PACKER_FORMAT="hcl"

if [[ "${PACKER_FORMAT}" == "json" ]]; then
  PACKER_VAR_FORMAT="json"
  PACKER_BUILD_FORMAT="json"
elif [[ "${PACKER_FORMAT}" == "hcl" ]]; then
  PACKER_VAR_FORMAT="json.pkrvars.hcl"
  PACKER_BUILD_FORMAT="json.pkr.hcl"
fi

PACKER_DEBUG=0
PACKER_LOG=1
#PACKER_ON_ERROR=abort
PACKER_ON_ERROR=ask
PACKER_FORCE_BUILD=1

function build_vm_template() {

  VM_DIST=$1
  VM_DIST_VERSION=$2
  VM_DIST_ISO=$3
  VM_BUILDER=${4:-vsphere-iso}

  ## ref: https://stackoverflow.com/questions/15870480/how-to-convert-a-date-time-string-to-an-integer-in-bash-shell
#  RUN_ID=$(date "+%s%N" | cut -b1-13)
  RUN_ID="test"

  VM_NAME=vm-template-${VM_DIST}-${VM_DIST_VERSION}-${RUN_ID}
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

#  BUILD_CONFIG=${PROJECT_DIR}/templates/${VM_DIST_DIR}/build-config.json
#  BUILD_CONFIG="${VM_DIST_DIR}/build-config.${PACKER_BUILD_FORMAT}"
  BUILD_CONFIG="${VM_DIST_DIR}/"

  ## ref: https://stackoverflow.com/questions/34521084/command-for-debugging-and-log-packer-build-in-windows
  PACKER_CMD_ARRAY=("env PACKER_LOG=${PACKER_LOG}")
  PACKER_CMD_ARRAY+=("BUILD_TAG=${BUILD_TAG}")
  PACKER_CMD_ARRAY+=("packer build -only ${VM_BUILDER}.*")
  PACKER_CMD_ARRAY+=("-on-error=${PACKER_ON_ERROR}")
  if [[ "${PACKER_VAR_FORMAT}" == "json" ]]; then
    PACKER_CMD_ARRAY+=("-var-file=common-vars.${PACKER_VAR_FORMAT}")
  fi
  PACKER_CMD_ARRAY+=("-var-file=env-vars.${BUILD_ENV}.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_DIR}/distribution-vars.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_VERSION_DIR}/server/box_info.${BUILD_FLAVOR}.${PACKER_VAR_FORMAT}")
  PACKER_CMD_ARRAY+=("-var-file=${VM_DIST_VERSION_DIR}/server/template.${PACKER_VAR_FORMAT}")
#  PACKER_CMD_ARRAY+=("-var vm_name=${VM_NAME}")
  PACKER_CMD_ARRAY+=("-var vm_template_build_name=${VM_NAME}")
  PACKER_CMD_ARRAY+=("-var vm_template_build_type=${BUILD_FLAVOR}")
  PACKER_CMD_ARRAY+=("-var vm_template_name=${VM_NAME}-${BUILD_FLAVOR}-${BUILD_ENV}")
  PACKER_CMD_ARRAY+=("-var vm_build_env=${BUILD_ENV}")
  PACKER_CMD_ARRAY+=("-var iso_dir=${VM_DIST_VERSION_DIR}")
  PACKER_CMD_ARRAY+=("-var iso_file=${VM_DIST_ISO}")
  if [[ ${PACKER_FORCE_BUILD} -ne 0 ]]; then
    PACKER_CMD_ARRAY+=("-force")
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

  IFS=$'\n'
  for VAR_NAME in ${PACKER_ENV_VARS}
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
    exit 1
  fi

}


echo "*******************************"
echo "Synchronize json config to HCL2"
./convert_json2hcl.sh

echo "*******************************"
echo "Validate all necessary env vars exist"
validate_env_vars

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
    VM_DIST_ISO="${DIST_INFO_ARRAY[2]}"

    echo "VM_DIST=[$VM_DIST]"
    echo "VM_DIST_VERSION=[$VM_DIST_VERSION]"
    echo "VM_DIST_ISO=[$VM_DIST_ISO]"

    echo "Run packer build"
    build_vm_template "${VM_DIST}" "${VM_DIST_VERSION}" "${VM_DIST_ISO}"

  fi

done
