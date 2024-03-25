#!/usr/bin/env bash

set -e
set -x

TEMPLATE_BUILD_INFO_FILEPATH="/etc/.vm-template.env"
TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH="/etc/ansible/facts.d/vm-template-build.fact"

if [[ "$EUID" = 0 ]]; then
    echo "(1) set to root"
else
  echo "****************************"
  echo "** user is not root!"
  echo "**   This script must be run as root or with sudo, exiting"
  echo "****************************"
  exit 1
fi

echo '==> Add template build info'
echo "VM_TEMPLATE_BUILD_USERNAME=${BUILD_USERNAME}" > "${TEMPLATE_BUILD_INFO_FILEPATH}"
echo "VM_TEMPLATE_BUILD_JOB_URL=${BUILD_JOB_URL}" > "${TEMPLATE_BUILD_INFO_FILEPATH}"
echo "VM_TEMPLATE_BUILD_JOB_ID=${BUILD_JOB_ID}" >> "${TEMPLATE_BUILD_INFO_FILEPATH}"
echo "VM_TEMPLATE_BUILD_GIT_COMMIT_HASH=${BUILD_GIT_COMMIT_HASH}" >> "${TEMPLATE_BUILD_INFO_FILEPATH}"

echo '==> Add template ansible facts info'
mkdir -p /etc/ansible/facts.d
echo "vm_template_build_username=${BUILD_USERNAME}" > "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"
echo "vm_template_build_job_url=${BUILD_JOB_URL}" > "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"
echo "vm_template_build_job_id=${BUILD_JOB_ID}" >> "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"
echo "vm_template_build_git_commit_hash=${BUILD_GIT_COMMIT_HASH}" >> "${TEMPLATE_BUILD_INFO_ANSIBLE_FACTS_FILEPATH}"

### set permissions
chmod 0644 "${TEMPLATE_BUILD_INFO_FILEPATH}"
cp -p "${TEMPLATE_BUILD_INFO_FILEPATH}" /home/${BUILD_USERNAME}/
