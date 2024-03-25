#!/usr/bin/env bash

export PATH=$PATH:~/.venv/ansible/bin

cd /var/tmp/packer-provisioner-ansible-local

ansible-playbook bootstrap_vm_template.yml \
  --tag vm-template \
  --vault-password-file=~/.vault_pass \
  -e @./vars/vault.yml \
  -c local \
  -i xenv_groups.yml
