d-i partman-auto/disk string /dev/${device}
d-i partman-auto/method string lvm
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-lvm/device_remove_lvm boolean true
%{ if length(lvm) == 0 ~}
d-i partman-auto/choose_recipe select atomic
%{ else ~}
%{ for volume_group in lvm ~}
d-i partman-auto-lvm/new_vg_name string ${volume_group.vg_name}
%{ endfor ~}

# Force UEFI booting ('BIOS compatibility' will be lost). Default: false.
d-i partman-efi/non_efi_system boolean true

# Ensure the partition table is GPT - this is required for EFI
d-i partman-partitioning/choose_label select gpt
d-i partman-partitioning/default_label string gpt

%{ if swap == false ~}
d-i partman-basicfilesystems/no_swap boolean false
%{ endif ~}
d-i partman-auto/expert_recipe string \
  custom :: \
%{ for partition in partitions ~}
%{ if lookup(partition, "volume_group", "") == "" ~}
%{ if partition.size != -1 ~}
    ${partition.size} ${partition.size} ${partition.size} ${partition.format.fstype} \
%{ else ~}
    100 100 -1 ${partition.format.fstype} \
%{ endif ~}
    $primary{ } \
%{ if partition.mount.path == "/boot" ~}
    $bootable{ } \
    mountpoint{ /boot } \
    method{ format } \
%{ endif ~}
%{ if partition.mount.path == "/boot/efi" ~}
    mountpoint{ /boot/efi } \
    method{ efi } \
%{ endif ~}
%{ if partition.mount.path != "/boot" && partition.mount.path != "/boot/efi" ~}
%{ if partition.mount.path != "" ~}
    mountpoint{ ${partition.mount.path} } \
%{ endif ~}
    method{ ${partition.format.fstype} } \
%{ endif ~}
    format{ } \
%{ if partition.format.fstype != "swap" ~}
    use_filesystem{ } \
%{ if partition.format.fstype == "fat32" ~}
    filesystem{ vfat } \
%{ else ~}
    filesystem{ ${partition.format.fstype} } \
%{ endif ~}
%{ endif ~}
    label { ${partition.format.label} } \
%{ for option in split(",", lookup(partition.mount, "options", "")) ~}
%{ if option != "" ~}
    options/${option}{ ${option} } \
%{ endif ~}
%{ endfor ~}
    . \
%{ else ~}
%{ for volume_group in lvm ~}
%{ if volume_group.vg_name == partition.volume_group ~}
%{ for partition in volume_group.partitions ~}
%{ if partition.size != -1 ~}
    ${partition.size} ${partition.size} ${partition.size}
%{~ else ~}
    100 100 -1
%{~ endif ~}
%{ if partition.format.fstype == "swap" ~}
 linux-swap \
%{ else ~}
 ${partition.format.fstype} \
%{ endif ~}
    $lvmok{ } \
%{ if partition.mount.path != "" ~}
    mountpoint{ ${partition.mount.path} } \
%{ endif ~}
    lv_name{ ${partition.lv_name} } \
    in_vg { ${volume_group.vg_name} } \
%{ if partition.format.fstype == "swap" ~}
    method{ swap } \
%{ else ~}
    method{ format } \
%{ endif ~}
    format{ } \
%{ if partition.format.fstype != "swap" ~}
    use_filesystem{ } \
    filesystem{ ${partition.format.fstype} } \
%{ endif ~}
    label { ${partition.format.label} } \
%{ for option in split(",", lookup(partition.mount, "options", "")) ~}
%{ if option != "" ~}
    options/${option}{ ${option} } \
%{ endif ~}
%{ endfor ~}
    . \
%{ endfor ~}
%{ endif ~}
%{ endfor ~}
%{ endif ~}
%{ endfor ~}
%{ endif ~}

d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
