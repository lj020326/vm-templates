#!/bin/bash -eux

set -e
set -x

ANSIBLE_STAGING_DIRECTORY_DEFAULT="/var/tmp/packer-provisioner-ansible-local"
ANSIBLE_COLLECTION_REQUIREMENTS_FILE_DEFAULT="/collections/requirements.yml"

VENV_BINDIR_DEFAULT="${HOME}/.venv/ansible/bin"

__ANSIBLE_STAGING_DIRECTORY="${ANSIBLE_STAGING_DIRECTORY:-"${ANSIBLE_STAGING_DIRECTORY_DEFAULT}"}"
__VENV_BINDIR="${VENV_DIR:-"${VENV_BINDIR_DEFAULT}"}"

echo "==> Setup ansible collections"
mkdir -p "${__ANSIBLE_STAGING_DIRECTORY}/galaxy_collections/ansible_collections/"
#cd "${__ANSIBLE_STAGING_DIRECTORY}/galaxy_collections/ansible_collections/"

export -p | sed 's/declare -x //' | sed 's/export //'

env PATH="${PATH}:${__VENV_BINDIR}" ansible-galaxy collection install --upgrade \
  -r "${__ANSIBLE_STAGING_DIRECTORY}/requirements.yml" \
  -p "${__ANSIBLE_STAGING_DIRECTORY}/galaxy_collections"

#env PATH="${PATH}:${__VENV_BINDIR}" ansible-galaxy collection install \
#  -r "${__ANSIBLE_STAGING_DIRECTORY}/requirements.yml" \
#  -p ~/.ansible/collections

#env PATH="${PATH}:${__VENV_BINDIR}" ansible-galaxy collection install \
#  -r "${__ANSIBLE_STAGING_DIRECTORY}/requirements.yml" \
#  -p "${__ANSIBLE_STAGING_DIRECTORY}/galaxy_collections"
