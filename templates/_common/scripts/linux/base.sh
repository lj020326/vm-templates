#!/usr/bin/env bash

set -e
set -x

## ref: https://stackoverflow.com/questions/42875809/checking-sudo-in-bash-script-with-if-statements
if [[ "$EUID" = 0 ]]; then
    echo "(1) set to root"
else
  echo "****************************"
  echo "** user is not root!"
  echo "**   This script must be run as root or with sudo, exiting"
  echo "****************************"
  exit 1
fi

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    id=$ID
    os_version_id=$VERSION_ID

elif [ -f /etc/redhat-release ]; then
    id="$(awk '{ print tolower($1) }' /etc/redhat-release | sed 's/"//g')"
    os_version_id="$(awk '{ print $3 }' /etc/redhat-release | sed 's/"//g' | awk -F. '{ print $1 }')"
fi

if [[ $id == "ol" ]]; then
    os_version_id_short="$(echo $os_version_id | cut -f1 -d".")"
else
    os_version_id_short="$(echo $os_version_id | cut -f1-2 -d".")"
fi

if [[ $id == "alpine" ]]; then
    chmod u+s /usr/bin/sudo
    apk add python alpine-sdk || true

elif [[ $id == "arch" ]]; then
    yes | pacman -Syyu && yes | pacman -S gc guile autoconf automake \
        binutils bison fakeroot file findutils flex gcc gettext grep \
        groff gzip libtool m4 make pacman patch pkgconf sed sudo systemd \
        texinfo util-linux which python-setuptools python-virtualenv python-pip \
        python-pyopenssl python2-setuptools python2-virtualenv python2-pip \
        python2-pyopenssl

elif [[ $id == "centos" || $id == "ol" ]]; then

    if [[ $id == "centos" ]]; then
      if [[ $os_version_id_short -ge 8 ]]; then
        ## ref: https://techglimpse.com/failed-metadata-repo-appstream-centos-8/
        ## ref: https://forums.centos.org/viewtopic.php?t=78708
        ## ref: https://gist.github.com/forevergenin/4bf75a5396183b83121fa971e54d7b04
        if [ "$(find /etc/yum.repos.d/ -type f -name CentOS-*.repo | wc -l)" -ge "1" ]; then
          mkdir -p /etc/yum.repos.d/dist
          cp -p /etc/yum.repos.d/*.repo /etc/yum.repos.d/dist/
          sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
#          sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://mirror.centos.org|g' /etc/yum.repos.d/CentOS-*.repo
#          sed -i 's|^#baseurl=|baseurl=|g' /etc/yum.repos.d/CentOS-*.repo
#          sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux*
#          sed -i 's|#baseurl=http://mirror.centos.org/$contentdir/|baseurl=https://vault.centos.org/centos/|g' /etc/yum.repos.d/CentOS-Linux*.repo
#          sed -i 's|#baseurl=http://mirror.centos.org/$contentdir/$releasever/\(.*\)/$basearch/os/|baseurl=https://vault.centos.org/centos/8/\1/$basearch/os/|g' /etc/yum.repos.d/CentOS-Linux*.repo
          sed -i 's|#baseurl=http://mirror.centos.org/$contentdir/$releasever/\(.*\)/$basearch/os/|baseurl=https://vault.centos.org/$contentdir/$releasever/\1/$basearch/os/|g' /etc/yum.repos.d/CentOS-Linux*.repo

#          dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${os_version_id_short}.noarch.rpm

          ## ref: https://stackoverflow.com/questions/9450120/openssl-hangs-and-does-not-exit
          echo QUIT | openssl s_client -showcerts -servername vault.centos.org -connect vault.centos.org:443 \
            | openssl x509 -outform PEM > /etc/pki/ca-trust/source/anchors/centos-cacert-updated.pem \
            && update-ca-trust

#          if [ "$(rpm -qa | grep centos | grep release | wc -l)" -ge "1" ]; then
#            dnf clean all
#            ## ref: https://www.techrepublic.com/article/how-to-convert-centos-8-to-centos-8-stream/
#            dnf install centos-release-stream -y
#            dnf swap -y centos-linux-repos centos-stream-repos
#            dnf distro-sync
#          fi
        else
          dnf install -y epel-release
        fi

        dnf -y update
        systemctl daemon-reload
        dnf -y install epel-release
      else
        sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/*.repo
        sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://mirror.centos.org|g' /etc/yum.repos.d/*.repo
#        rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-${os_version_id_short}.noarch.rpm
        yum -y install epel-release
      fi
    else
#      yum -y install epel-release
      rpm -ivh "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${os_version_id_short}.noarch.rpm"
#      if [[ $os_version_id_short -eq 7 ]]; then
#        rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#      elif [[ $os_version_id_short -eq 8 ]]; then
#        rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
#      fi
    fi

    if [[ $os_version_id_short -lt 8 ]]; then
      yum -y install cloud-utils-growpart python-devel
    else
      dnf -y install cloud-utils-growpart platform-python-devel
    fi

elif [[ $id == "debian" ]]; then
    apt-get update
    echo "libc6:amd64     libraries/restart-without-asking        boolean true" | debconf-set-selections
    echo "libssl1.1:amd64 libssl1.1/restart-services      string" | debconf-set-selections
    if [[ $os_version_id -lt 10 ]]; then
      apt-get install -y python-minimal libreadline-gplv2-dev
    fi
    apt-get install -y linux-headers-"$(uname -r)" \
        build-essential \
        python3-venv \
        zlib1g-dev \
        libssl-dev \
        unzip

    if [[ ! -f /etc/vyos_build ]]; then
        if [[ $os_version_id -gt 7 ]]; then
            apt-get -y install cloud-initramfs-growroot
        fi
    fi

elif [[ $id == "elementary" ]]; then
    apt-get update
    echo "libc6:amd64     libraries/restart-without-asking        boolean true" | debconf-set-selections
    echo "libssl1.1:amd64 libssl1.1/restart-services      string" | debconf-set-selections
    apt-get install -y python-minimal linux-headers-"$(uname -r)" \
        build-essential zlib1g-dev libssl-dev libreadline-gplv2-dev unzip

    if [[ ! -f /etc/vyos_build ]]; then
        if [[ $os_version_id -gt 7 ]]; then
            apt-get -y install cloud-initramfs-growroot
        fi
    fi

elif [[ $id == "fedora" ]]; then
    if [[ $os_version_id -lt 30 ]]; then
        dnf -y install python-devel python-dnf
    else
        dnf -y install initscripts python-devel python3-dnf
    fi

elif [[ $id == "linuxmint" ]]; then
    apt-get update
    echo "libc6:amd64     libraries/restart-without-asking        boolean true" | debconf-set-selections
    echo "libssl1.1:amd64 libssl1.1/restart-services      string" | debconf-set-selections
    apt-get install -y python-minimal linux-headers-"$(uname -r)" \
        build-essential zlib1g-dev libssl-dev libreadline-gplv2-dev unzip

    if [[ ! -f /etc/vyos_build ]]; then
        if [[ $os_version_id -gt 7 ]]; then
            apt-get -y install cloud-initramfs-growroot
        fi
    fi

elif [[ $id == "opensuse" || $id == "opensuse-leap" ]]; then
    zypper --non-interactive install python-devel

elif [[ $id == "ubuntu" ]]; then
    if (($(echo $os_version_id '==' 12.04 | bc))); then
        apt-get clean
        rm -r /var/lib/apt/lists/*
    fi
    apt-get update
    ## ref: https://askubuntu.com/questions/136881/debconf-dbdriver-config-config-dat-is-locked-by-another-process-resource-t
    fuser -v -k /var/cache/debconf/config.dat || true
#    rm /var/cache/debconf/*.dat
#    rm -f /var/cache/debconf/config.dat

    sleep 5

    ## ref: https://github.com/moby/moby/issues/27988
    echo "debconf debconf/frontend select Noninteractive" | debconf-set-selections
    echo "libc6:amd64     libraries/restart-without-asking        boolean true" | debconf-set-selections
    echo "libssl1.1:amd64 libssl1.1/restart-services      string" | debconf-set-selections
    if [[ $os_version_id_short -lt 20.04 ]]; then
        apt-get install -y python-minimal
    fi
    if [[ $os_version_id_short -lt 22.04 ]]; then
      apt-get install -y libreadline-gplv2-dev
    fi
    apt-get install -y linux-headers-"$(uname -r)" \
        build-essential \
        python3-venv \
        zlib1g-dev \
        libssl-dev \
        unzip

    if [[ ! -f /etc/vyos_build ]]; then
        apt-get -y install cloud-initramfs-growroot
    fi
fi

if [[ $id == "debian" || $id == "elementary" || $id == "linuxmint" || $id == "ubuntu" ]]; then
    if [[ $id == "elementary" || $id == "linuxmint" ]]; then
        # Remove /etc/rc.local used for provisioning
        rm /etc/rc.local
        if [ -f /etc/rc.local.orig ]; then
            mv /etc/rc.local.orig /etc/rc.local
        fi
    fi

    # Check for /etc/rc.local and create if needed. This has been depricated in
    # Debian 9 and later. So we need to resolve this in order to regenerate SSH host
    # keys.
    if [ ! -f /etc/rc.local ]; then
        bash -c "echo '#!/bin/sh -e' > /etc/rc.local"
        bash -c "echo 'test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server' >> /etc/rc.local"
        bash -c "echo 'exit 0' >> /etc/rc.local"
        chmod +x /etc/rc.local

        ## ref: https://www.linuxbabe.com/linux-server/how-to-enable-etcrc-local-with-systemd
        cat <<_EOF_ | bash -c "cat > /etc/systemd/system/rc-local.service"
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local

[Service]
 Type=forking
 ExecStart=/etc/rc.local start
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes
 SysVStartPriority=99

[Install]
 WantedBy=multi-user.target
_EOF_

        systemctl daemon-reload
        systemctl enable rc-local
        systemctl start rc-local
    else
        bash -c "sed -i -e 's|exit 0||' /etc/rc.local"
        bash -c "sed -i -e 's|.*test -f /etc/ssh/ssh_host_dsa_key.*||' /etc/rc.local"
        bash -c "echo 'test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server' >> /etc/rc.local"
        bash -c "echo 'exit 0' >> /etc/rc.local"
    fi
fi

###PATH_TO_PIP=$(which pip)
###if [ -x "$PATH_TO_PIP" ] ; then
#if [[ $(type -P "pip") ]]; then
#  ## Disable warning for root user package management
#  ## ref: https://github.com/pypa/pip/pull/10990#issuecomment-1091476480
#  export PIP_NO_WARN_ABOUT_ROOT_USER=0
#
#  ## ref: https://github.com/pypa/pip/issues/11179#issuecomment-1152766374
#  ## or use `--root-user-action ignore` option in each pip command
#  export PIP_ROOT_USER_ACTION=ignore
#  pip install netaddr
#fi

BUILD_USER=${BUILD_USERNAME:-osbuilduser}

echo "==> Configuring ${BUILD_USER} sudo configs"

echo "==> Add ${BUILD_USER} user to sudoers."
echo "${BUILD_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${BUILD_USER} \
  && chmod 440 /etc/sudoers.d/${BUILD_USER}

echo "==> Setup Ansible pipelining+sudo support for USER=${BUILD_USER}"
echo "Defaults !requiretty" >> /etc/sudoers.d/${BUILD_USER} \
  && chmod 440 /etc/sudoers.d/${BUILD_USER}

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

## ref: https://github.com/hashicorp/packer/issues/4623#issuecomment-315489018

## Fix machine-id issue with duplicate IP addresses being assigned
#if [ -f /etc/machine-id ]; then
#    truncate -s 0 /etc/machine-id
#fi

## handle corp FW cert injection
## ref: https://stackoverflow.com/questions/75763525/curl-35-error0a000152ssl-routinesunsafe-legacy-renegotiation-disabled
#echo 'Options = UnsafeLegacyRenegotiation' >> /etc/ssl/openssl.cnf
