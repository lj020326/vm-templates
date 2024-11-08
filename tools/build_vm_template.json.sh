#!/usr/bin/env bash

#VM_DIST_LIST="
#Debian|9|debian-9.13.0-amd64-netinst.iso
#CentOS|8|CentOS-8.5.2111-x86_64-dvd1.iso
#CentOS|8-stream|CentOS-Stream-8-x86_64-latest-dvd1.iso
#"

VM_DIST_LIST="
CentOS|8|CentOS-8.5.2111-x86_64-dvd1.iso
"

PROJECT_DIR=$( git rev-parse --show-toplevel )
cd "${PROJECT_DIR}/templates"

function build_vm_template() {

  VM_DIST=$1
  VM_DIST_VERSION=$2
  VM_DIST_ISO=$3
  VM_BUILDER=${4:-vsphere-iso}

  PACKER_LOG=1
#  PACKER_ON_ERROR=abort
  PACKER_ON_ERROR=ask
  PACKER_FORCE_BUILD=0
  PACKER_DEBUG=0

  VAULTPASS_FILEPATH="${HOME}/.vault_pass"
  if [[ -f "${PROJECT_DIR}/.vault_pass" ]]; then
    VAULTPASS_FILEPATH="${PROJECT_DIR}/.vault_pass"
  fi

  ###########################################################
  ## DO NOT REMOVE :
  ##   ENV var required in common-vars.json
  export ANSIBLE_VAULT_PASSWORD=$(<"${VAULTPASS_FILEPATH}")

  ## ref: https://stackoverflow.com/questions/15870480/how-to-convert-a-date-time-string-to-an-integer-in-bash-shell
#  RUN_ID=$(date "+%s%N" | cut -b1-13)
  RUN_ID="test"

  VM_BUILD_ID=vm-template-${VM_DIST}-${VM_DIST_VERSION}-${RUN_ID}
  VM_DIST_DIR="${VM_DIST}/${VM_DIST_VERSION}"
#  BUILD_CONFIG=${PROJECT_DIR}/templates/${VM_DIST}/build-config.json
  BUILD_CONFIG="${VM_DIST}/build-config.json"

  ## ref: https://stackoverflow.com/questions/34521084/command-for-debugging-and-log-packer-build-in-windows
  PACKER_CMD="env PACKER_LOG=${PACKER_LOG} "
  PACKER_CMD+="packer build -only ${VM_BUILDER}"
  PACKER_CMD+=" -on-error=${PACKER_ON_ERROR}"
  PACKER_CMD+=" -var-file=common-vars.json"
  PACKER_CMD+=" -var-file=${VM_DIST}/distribution-vars.json"
  PACKER_CMD+=" -var-file=${VM_DIST_DIR}/server/box_info.json"
  PACKER_CMD+=" -var-file=${VM_DIST_DIR}/server/template.json"
  PACKER_CMD+=" -var vm_build_id=${VM_BUILD_ID}"
  PACKER_CMD+=" -var iso_dir=${VM_DIST_DIR}"
  PACKER_CMD+=" -var iso_file=${VM_DIST_ISO}"
  if [[ ${PACKER_FORCE_BUILD} -ne 0 ]]; then
    PACKER_CMD+=" -force"
  fi
  if [[ ${PACKER_DEBUG} -ne 0 ]]; then
    PACKER_CMD+=" -debug"
  fi
  PACKER_CMD+=" ${BUILD_CONFIG}"

  echo "************************************"
  echo "** running command=[${PACKER_CMD}]"
  eval "${PACKER_CMD}"

}

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
    VM_DIST=${DIST_INFO_ARRAY[0]}
    VM_DIST_VERSION=${DIST_INFO_ARRAY[1]}
    VM_DIST_ISO=${DIST_INFO_ARRAY[2]}

    echo "VM_DIST=[$VM_DIST]"
    echo "VM_DIST_VERSION=[$VM_DIST_VERSION]"
    echo "VM_DIST_ISO=[$VM_DIST_ISO]"

    echo "Run packer build"
    build_vm_template "${VM_DIST}" "${VM_DIST_VERSION}" "${VM_DIST_ISO}"

  fi

done
