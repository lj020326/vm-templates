
### Initialize any invalid partition tables found on disks.
zerombr

### Removes partitions from the system, prior to creation of new partitions.
### By default, no partitions are removed.
### ref: https://forums.centos.org/viewtopic.php?t=61446
### ref: https://unix.stackexchange.com/questions/594614/kickstart-install-rhel-storage-configuration-failed-not-enough-space-in
### --linux	erases all Linux partitions.
### --initlabel Initializes a disk (or disks) by creating a default disk label for all disks in their respective architecture.
clearpart --all --initlabel
#clearpart --all --initlabel --drives=sda,sdb
#clearpart --all --initlabel --drives=sda
#clearpart --all --initlabel
##ignoredisk --only-use=sda

##########################
### Disk partitioning information
### ref: https://docs.centos.org/en-US/centos/install-guide/Kickstart2/
### ref: https://www.golinuxhub.com/2018/05/sample-kickstart-partition-example-raid/
### ref: https://community.spiceworks.com/topic/2339397-create-lvm-partition-with-kickstart
### ref: https://serverfault.com/questions/826006/centos-rhel-7-lvm-partitioning-in-kickstart
### ref: https://github.com/vinceskahan/docs/blob/master/files/kickstart/lvm-partitioning-in-ks.md
### ref: https://gainanov.pro/eng-blog/linux/centos-installation-with-kickstart/
### ref: https://serverfault.com/questions/1049693/oel8-kickstart-install-on-esxi-hangs-at-reached-target-basic-system-why
### ref: https://stackoverflow.com/questions/68007540/terraform-conditionally-execute-some-lines-of-code-in-template-file
### ref: https://developer.hashicorp.com/packer/docs/templates/hcl_templates/functions/file/templatefile

### Modify partition sizes for the virtual machine hardware.
### Create primary system partitions.
%{ if vm_disk_partition_auto=="true" }
#autopart --nohome --nolvm --noboot
autopart --nolvm

%{ else }

#########################
## disk partitions
%{ for partition_config in vm_disk_configs[vm_template_type].vm_disk_partition_list ~}
part ${partition_config}
%{ endfor ~}

#########################
## volume groups
%{ for volume_group_config in vm_disk_configs[vm_template_type].vm_disk_volgroup_list ~}
volgroup ${volume_group_config}
%{ endfor ~}

#########################
## logical volumes
%{ for logical_volume_config in vm_disk_configs[vm_template_type].vm_disk_lvm_list ~}
logvol ${logical_volume_config}
%{ endfor ~}

%{ endif }
