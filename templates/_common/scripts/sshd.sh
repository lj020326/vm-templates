#!/usr/bin/env bash

set -e
set -x

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

sudo service sshd restart
