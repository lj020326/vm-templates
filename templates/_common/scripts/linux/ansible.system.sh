#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-${BUILD_USERNAME}}

echo "==> Add ${BUILD_USERNAME} user to sudoers."
echo "${SSH_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${SSH_USER} && chmod 440 /etc/sudoers.d/${SSH_USER}

echo "==> Setup Ansible pipelining+sudo support for USER=${SSH_USER}"
echo "Defaults !requiretty" >> /etc/sudoers.d/${SSH_USER} && chmod 440 /etc/sudoers.d/${SSH_USER}
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

## ref: https://github.com/hashicorp/packer/issues/4623#issuecomment-315489018

## These SSH configuration values are set when the server comes up so that ${BUILD_USERNAME} can
## maintain a hanging, trafficless SSH connection. They're reverted by the ssh recipe.
##
#sed -i -e '/ClientAliveInterval 300/{ s/.*/ClientAliveInterval 1000/ }' /etc/ssh/sshd_config
#sed -i -e '/ClientAliveCountMax 0/{ s/.*/ClientAliveCountMax 3/ }'      /etc/ssh/sshd_config
#sed -i -e '/#TCPKeepAlive yes/{ s/.*/TCPKeepAlive yes/ }'               /etc/ssh/sshd_config
echo "ClientAliveInterval 1000" >> /etc/ssh/sshd_config
echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config
service sshd restart

## Disable warning for root user package management
## ref: https://github.com/pypa/pip/pull/10990#issuecomment-1091476480
#export PIP_NO_WARN_ABOUT_ROOT_USER=0

## ref: https://github.com/pypa/pip/issues/11179#issuecomment-1152766374
## or use `--root-user-action ignore` option in each pip command
export PIP_ROOT_USER_ACTION=ignore

echo "==> Install latest ansible"
## ref: http://www.freekb.net/Article?id=214
## ref: https://github.com/pyca/pyopenssl/issues/559
#pip3 install --upgrade pip ansible virtualenv cryptography pyopenssl
#pip3 install --upgrade pip ansible cryptography pyopenssl
pip3 install --upgrade wheel
pip3 install --upgrade pip
pip3 install --upgrade ansible
#pip3 install --upgrade cryptography
#pip3 install --upgrade pyopenssl

pip3 install --upgrade netaddr

#PATH_TO_PIP=$(which pip)
#if [ -x "$PATH_TO_PIP" ] ; then
if [[ $(type -P "pip") ]]; then
  pip install netaddr
fi

#pip install netaddr || true

#ln -s /usr/local/bin/ansible /usr/bin/ansible
#ln -s /usr/local/bin/ansible-galaxy /usr/bin/ansible-galaxy
#ln -s /usr/local/bin/ansible-playbook /usr/bin/ansible-playbook
#ln -s /usr/local/bin/virtualenv /usr/bin/virtualenv

### setup ansible vault password
### ref: https://github.com/hashicorp/packer/issues/555#issuecomment-145749614
#echo {{user `ansible_vault_password`}} > ~/.vault_pass
#chmod 600 ~/.vault_pass

#echo "export PATH=$PATH:~/.local/bin" >> ~/.bash_profile

#echo "==> Install upgraded ansible collections"
#export PATH=$PATH:/usr/local/bin
#ansible-galaxy collection install -U ansible.utils
#ansible-galaxy collection install -U community.general
