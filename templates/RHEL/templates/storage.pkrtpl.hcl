### Sets how the boot loader should be installed.
bootloader --location=mbr

### Initialize any invalid partition tables found on disks.
zerombr

### Removes partitions from the system, prior to creation of new partitions.
### By default, no partitions are removed.
### --all	Erases all partitions from the system
### --initlabel Initializes a disk (or disks) by creating a default disk label for all disks in their respective architecture.
clearpart --all --initlabel

%{ if partitions==[] }
#autopart --nohome --nolvm --noboot
autopart --nolvm

%{ else }

#########################
### disk partitions
### Modify partition sizes for the virtual machine hardware.
### Create primary system partitions.
%{ for partition in partitions ~}
part
%{~ if partition.pv_name != "" ~}
 ${partition.pv_name}
%{~ endif ~}
%{~ if partition.format.fstype == "swap" ~}
 swap
%{~ else ~}
 ${partition.mount.path}
%{~ endif ~}
%{~ if partition.format.label != "" ~}
 --label=${partition.format.label}
%{~ endif ~}
%{~ if partition.format.fstype != "" ~}
%{~ if partition.format.fstype == "fat32" ~}
 --fstype vfat
%{~ else ~}
 --fstype ${partition.format.fstype}
%{~ endif ~}
%{~ endif ~}
%{~ if partition.drive != "" ~}
 --ondrive="${partition.drive}"
%{~ endif ~}
%{~ if partition.mount.options != "" ~}
  --fsoptions="${partition.mount.options}"
%{~ endif ~}
%{~ if partition.size != -1 ~}
 --size=${partition.size}
%{~ else ~}
 --size=100 --grow
%{ endif ~}

%{ endfor ~}

#########################
## Partition information
## ref: https://docs.centos.org/en-US/centos/install-guide/Kickstart2/
## ref: https://www.golinuxhub.com/2018/05/sample-kickstart-partition-example-raid/
## ref: https://community.spiceworks.com/topic/2339397-create-lvm-partition-with-kickstart
## ref: https://serverfault.com/questions/826006/centos-rhel-7-lvm-partitioning-in-kickstart
## ref: https://github.com/vinceskahan/docs/blob/master/files/kickstart/lvm-partitioning-in-ks.md
## ref: https://gainanov.pro/eng-blog/linux/centos-installation-with-kickstart/
## ref: https://serverfault.com/questions/1049693/oel8-kickstart-install-on-esxi-hangs-at-reached-target-basic-system-why

#########################
### volume groups
### Create a logical volume management (LVM) group.
%{ for index, volume_group in lvm ~}
volgroup ${volume_group.vg_name} ${volume_group.pv_name}

#########################
### logical volumes
### Modify logical volume sizes for the virtual machine hardware.
### Create logical volumes.
%{ for partition in volume_group.partitions ~}
logvol
%{~ if partition.format.fstype == "swap" ~}
 swap
%{~ else ~}
 ${partition.mount.path}
%{~ endif ~}
 --name=${partition.lv_name} --vgname=${volume_group.vg_name} --label=${partition.format.label}
%{~ if partition.format.fstype == "fat32" ~}
 --fstype vfat
%{~ else ~}
 --fstype ${partition.format.fstype}
%{~ endif ~}
%{~ if partition.mount.options != "" ~}
 --fsoptions="${partition.mount.options}"
%{~ endif ~}
%{~ if partition.size != -1 ~}
 --size=${partition.size}
%{~ else ~}
 --size=100 --grow
%{ endif ~}

%{ endfor ~}
%{ endfor ~}

%{ endif }
