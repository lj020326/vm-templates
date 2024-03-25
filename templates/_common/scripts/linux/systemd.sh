#!/usr/bin/env bash

set -e
set -x

## This should be in sync with the systemd docker container image definitions found here:
## https://github.com/lj020326/systemd-python-dockerfiles/tree/master/systemd
#echo '==> Configuring systemd options'
#cd /lib/systemd/system/sysinit.target.wants/ \
#    && rm $(ls | grep -v systemd-tmpfiles-setup)
#
#echo '==> Removing systemd default options'
#rm -f /lib/systemd/system/multi-user.target.wants/* \
#    /etc/systemd/system/*.wants/* \
#    /lib/systemd/system/local-fs.target.wants/* \
#    /lib/systemd/system/sockets.target.wants/*udev* \
#    /lib/systemd/system/sockets.target.wants/*initctl* \
#    /lib/systemd/system/basic.target.wants/* \
#    /lib/systemd/system/anaconda.target.wants/* \
#    /lib/systemd/system/plymouth* \
#    /lib/systemd/system/systemd-update-utmp*

## ref: https://unix.stackexchange.com/questions/636843/how-to-disable-override-automatic-mounting-of-tmpfs-to-tmp-by-systemd
echo '==> Disable systemd tmp.mount'
systemctl disable tmp.mount || true
systemctl mask tmp.mount || true
