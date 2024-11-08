#!/usr/bin/env bash

set -e
set -x

__BUILD_USER_SSH_PUBLIC_KEY=${BUILD_USER_SSH_PUBLIC_KEY:-""}

echo '==> Configuring sshd_config options'
echo '==> Turning off sshd DNS lookup to prevent timeout delay'
#sudo bash -c "echo 'UseDNS no' >>/etc/ssh/sshd_config"
sudo sed -i -e 's/^UseDNS.*yes/UseDNS no/g' /etc/ssh/sshd_config

echo '==> Disabling GSSAPI authentication to prevent timeout delay'
#sudo bash -c "echo 'GSSAPIAuthentication no' >>/etc/ssh/sshd_config"
#sudo sed -i -e 's/^GSSAPIAuthentication.*yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config

## ref: https://eng.ucmerced.edu/soe/computing/services/ssh-based-service/ldap-ssh-access
## ref: https://gist.github.com/ThinGuy/b0f935b93f6f03b0ad132e7734d2b188
echo "==> Configure ssh to enable password auth"
sudo sed -i -e 's/^PasswordAuthentication.*no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

## ref: https://stackoverflow.com/questions/41062080/sshd-config-automatically-changes-rules-after-reboot
sudo mkdir -p /etc/cloud/cloud.cfg.d
sudo echo "ssh_pwauth: true" > /etc/cloud/cloud.cfg.d/00_defaults.cfg

## These SSH configuration values are set when the server comes up so that ${BUILD_USERNAME} can
## maintain a hanging, trafficless SSH connection. They're reverted by the ssh recipe.
##
#sed -i -e '/ClientAliveInterval 300/{ s/.*/ClientAliveInterval 1000/ }' /etc/ssh/sshd_config
#sed -i -e '/ClientAliveCountMax 0/{ s/.*/ClientAliveCountMax 3/ }'      /etc/ssh/sshd_config
#sed -i -e '/#TCPKeepAlive yes/{ s/.*/TCPKeepAlive yes/ }'               /etc/ssh/sshd_config
echo "ClientAliveInterval 1000" >> /etc/ssh/sshd_config
echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config

if [[ "${__BUILD_USER_SSH_PUBLIC_KEY}" != "" ]]; then
  echo "==> Install ${BUILD_USERNAME} SSH authorized keys"
  mkdir -p -m0700 /home/${BUILD_USERNAME}/.ssh/
  echo "${__BUILD_USER_SSH_PUBLIC_KEY}" > "/home/${BUILD_USERNAME}/.ssh/authorized_keys"

  ### set permissions
  chown "${BUILD_USERNAME}:${BUILD_USERNAME}" -R "/home/${BUILD_USERNAME}/.ssh"
  chmod 0600 "/home/${BUILD_USERNAME}/.ssh/authorized_keys"

#  ## ref: https://github.com/vinceskahan/docs/blob/master/files/kickstart/adding-ssh-keys-in-kickstart.md
#  ### fix up selinux context
#  restorecon -R /root/.ssh/
fi
