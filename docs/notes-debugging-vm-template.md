
# Debugging a VM template

## when kickstart fails

### Open Web console in build VM

[1 - Open vm web console to the build vm in vpshere](./img/vphere-web-console.png)

[2 - Open anaconda shell in build VM](./img/vsphere-web-console.png)

View the kickstart.cfg content:
```shell
# more /mnt/install/ks.cfg
```
[3 - More build VM kickstart.cfg](./img/vsphere-anaconda-more-kickstart.png)

[4 - View build VM kickstart.cfg](./img/vsphere-anaconda-more-kickstart.png)


and open the anaconda terminal shell:

## when packer fails in the ansible provisioner

Assuming the packer option to abort `-on-error=abort` is enabled, upon failing the pre-template VM instance will remain running for debugging purposes:

Example launch for debian9 template:
```shell
$ packer build -only vsphere-iso -on-error=abort \
  -var-file=common-vars.json \
  -var-file=Debian/distribution-vars.json \
  -var-file=Debian/9/server/box_info.json \
  -var-file=Debian/9/server/template.json \
  -var vm_build_id=packer-templates-debian-9-0040 \
  -var iso_dir=Debian/9 \
  -var iso_file=debian-9.13.0-amd64-netinst.iso \
  -debug /workspace/dettonville/infra/packer-templates/Debian/9/templates/Debian/build-config.json
```

```shell
$ ssh packer@10.10.100.95
```

```shell
packer@localhost:~$ ansible-playbook -vv bootstrap_vm_template.yml --vault-password-file=~/.vault_pass -c local -i vm_template.yml
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
