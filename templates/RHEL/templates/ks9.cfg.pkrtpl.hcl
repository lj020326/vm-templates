# Red Hat Enterprise Linux Server 9
# ref: https://github.com/vmware-samples/packer-examples-for-vsphere/blob/main/builds/linux/rhel/9/data/ks.pkrtpl.hcl

### Installs from the first attached CD-ROM/DVD on the system.
cdrom

### Performs the kickstart installation in text mode.
### By default, kickstart installations are performed in graphical mode.
text

### Accepts the End User License Agreement.
eula --agreed

### Sets the language to use during installation and the default language to use on the installed system.
lang ${vm_guest_os_language}

### Sets the default keyboard type for the system.
keyboard ${vm_guest_os_keyboard}

### Configure network information for target system and activate network devices in the installer environment (optional)
${network}

### Lock the root account.
rootpw --lock

### The selected profile will restrict root login.
### Add a user that can login and escalate privileges.
user --name=${build_username} --iscrypted --password=${build_password_encrypted} --groups=wheel

### Configure firewall settings for the system.
### --enabled	reject incoming connections that are not in response to outbound requests
### --ssh		allow sshd service through the firewall
firewall --enabled --ssh

### Sets up the authentication options for the system.
### The SSDD profile sets sha512 to hash passwords. Passwords are shadowed by default
### See the manual page for authselect-profile for a complete list of possible options.
authselect select sssd

### Sets the state of SELinux on the installed system.
### Defaults to enforcing.
selinux --enforcing

### Sets the system time zone.
timezone ${vm_guest_os_timezone}

### Partitioning
${storage}

### Modifies the default set of services that will run under the default runlevel.
services --enabled=NetworkManager,sshd

### Do not configure X on the installed system.
skipx

#########################
### Packages selection.
### package groups ref: https://access.redhat.com/solutions/10549
#%packages --ignoremissing --excludedocs
%packages --excludedocs
@core
virt-who
python3
## unnecessary firmware
-iwl*firmware
%end

### Post-installation commands.
%post
echo
echo "################################"
echo "# Running Post Configuration   #"
echo "################################"
#dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf makecache
dnf install -y sudo open-vm-tools perl
%{ if additional_packages != "" ~}
dnf install -y ${additional_packages}
%{ endif ~}
dnf clean all
echo "${build_username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${build_username}
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

#################
## NOTE:
## the following block of journald.conf updates resolves following noted issue:
##
## Data hash table of /run/log/journal/####/system.journal has a fill level at 75.1 (*), suggesting rotation
## ref: https://github.com/systemd/systemd/issues/22007
##
#################

# tune journald.conf
sed -e "s,^.*Compress=.*$,Compress=no,g" -i /etc/systemd/journald.conf
sed -e "s,^.*SplitMode=.*$,SplitMode=none,g" -i /etc/systemd/journald.conf
sed -e "s,^.*RuntimeMaxUse=.*$,RuntimeMaxUse=2M,g" -i /etc/systemd/journald.conf
sed -e "s,^.*RuntimeMaxFileSize=.*$,RuntimeMaxFileSize=128K,g" -i /etc/systemd/journald.conf
sed -e "s,^.*SystemMaxUse=.*$,SystemMaxUse=10M,g" -i /etc/systemd/journald.conf

## ref: https://github.com/canonical/packer-maas/issues/108
cp -vr /boot/efi/EFI/rocky /boot/efi/EFI/rhel

%end

#########################
### Reboot after the installation is complete.
### Run the Setup Agent on first boot
### --eject attempt to eject the media before rebooting.
#firstboot --disabled
reboot --eject
