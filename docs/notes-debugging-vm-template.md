
# Debugging a VM template

## when packer fails in the ansible provisioner

```shell
$ ssh packer@10.10.100.95
```

```shell
packer@localhost:~$ 
packer@localhost:~$ alias ll='ls -Fla'
packer@localhost:~$ cd /tmp/packer-provisioner-ansible-local/63be28e3-45d8-e5d3-cad9-04b168b4ae71/
packer@localhost:~$ cp -p bootstrap_vm_template.yml bootstrap_vm_firewall.yml
packer@localhost:~$ emacs bootstrap_vm_firewall.yml 
packer@localhost:~$ ansible-playbook -vv bootstrap_vm_firewall.yml --vault-password-file=~/.vault_pass -c local -i vm_template.yml
packer@localhost:~$ cat /lib/systemd/system/systemd-update-utmp.service 
packer@localhost:~$ hostnamectl | grep -i 'chassis: vm' | wc -l
packer@localhost:~$ ll /etc/systemd/system
packer@localhost:~$ ll /lib/systemd/system
packer@localhost:~$ ll /lib/systemd/system/
packer@localhost:~$ ll /lib/systemd/system/local-fs.target.wants/
packer@localhost:~$ ll /lib/systemd/system/local-fs.target.wants/tmp.mount
packer@localhost:~$ ll /lib/systemd/system/sysinit.target.wants/
packer@localhost:~$ ll /lib/systemd/system/sysinit.target.wants/ | grep systemd-tmpfiles-setup
packer@localhost:~$ ll /lib/systemd/system/sysinit.target.wants/ | grep -v systemd-tmpfiles-setup
packer@localhost:~$ mount -l | grep /tmp
packer@localhost:~$ nano bootstrap_vm_firewall.yml 
packer@localhost:~$ pip3 -V
packer@localhost:~$ pip freeze
packer@localhost:~$ pip -V
packer@localhost:~$ python2 -V
packer@localhost:~$ rm -f /lib/systemd/system/multi-user.target.wants/*     /etc/systemd/system/*.wants/*     /lib/systemd/system/local-fs.target.wants/*     /lib/systemd/system/sockets.target.wants/*udev*     /lib/systemd/system/sockets.target.wants/*initctl*     /lib/systemd/system/basic.target.wants/*     /lib/systemd/system/anaconda.target.wants/*     /lib/systemd/system/plymouth*     /lib/systemd/system/systemd-update-utmp*
packer@localhost:~$ sudo apt-get install python-firewall
packer@localhost:~$ sudo apt-get install python-firewalld
packer@localhost:~$ sudo apt -y install firewalld
packer@localhost:~$ sudo apt -y install libselinux-python
packer@localhost:~$ sudo apt -y install python
packer@localhost:~$ sudo apt -y install python2-firewall
packer@localhost:~$ sudo apt -y install python3-firewall
packer@localhost:~$ sudo apt -y install python-firewall
packer@localhost:~$ sudo apt -y remove firewalld
packer@localhost:~$ sudo apt -y uninstall firewalld
packer@localhost:~$ sudo pip3 freeze
packer@localhost:~$ sudo pip3 install firewall
packer@localhost:~$ sudo pip3 install firewalld
packer@localhost:~$ sudo pip install firewall
packer@localhost:~$ sudo su
packer@localhost:~$ sudo systemctl disable tmp.mount
packer@localhost:~$ sudo systemctl mask tmp.mount
packer@localhost:~$ sudo umount /tmp
packer@localhost:~$ systemctl disable tmp.mount
packer@localhost:~$ systemctl mask tmp.mount
packer@localhost:~$ systemctl status tmp.mount
packer@localhost:~$ which python2
packer@localhost:~$ which python3
packer@localhost:~$ exit
```
