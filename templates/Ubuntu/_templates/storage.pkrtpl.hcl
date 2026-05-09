storage:
%{ if partitions == [] ~}
  swap:
    size: 0
  layout:
    name: lvm
%{ else ~}
  config:
    # 1. Physical Disk
    - id: disk-${device}
      type: disk
      name: ''
      path: /dev/${device}
      ptable: gpt
      preserve: false
      grub_device: true
      wipe: superblock-recursive

%{ for index, partition in partitions ~}
    # 2. Partition partition-${index}
    - id: partition-${index}
      type: partition
      device: disk-${device}
      size: ${partition.size == -1 ? "-1" : "${partition.size}M"}
      number: ${index + 1}

    # Bootloader flags
%{ if firmware == "bios" && index == 0 ~}
      flag: bios_grub
%{ endif ~}
%{ if (firmware != "bios" && index == 0) ~}
      flag: boot
      grub_device: true
%{ endif ~}

    # Format + Mount (skip entirely for BIOS grub partition)
%{ if !(firmware == "bios" && index == 0) && partition.format.fstype != "" ~}
    # 3. Format partition-${index}
    - id: format-part-${index}
      type: format
      volume: partition-${index}
      label: ${partition.format.label}
      fstype: ${firmware != "bios" && index == 0 ? "fat32" : partition.format.fstype}

    # 4. Mount the (non-LVM) partition-${index}
    - id: mount-part-${index}
      type: mount
%{ if firmware != "bios" && index == 0 ~}
      path: /boot/efi
%{ else ~}
      path: ${partition.mount.path == "" ? "none" : partition.mount.path}
%{ endif ~}
      device: format-part-${index}
%{ if partition.mount.options != "" ~}
      options: ${partition.mount.options}
%{ endif ~}
%{ endif ~}
%{ endfor ~}

    # === LVM Volume Groups & Logical Volumes ===
%{ for vg_index, vg in lvm ~}
    # 6. LVM Volume Group ${vg_index}
    - id: volgroup-${vg.vg_name}
      type: lvm_volgroup
      name: ${vg.vg_name}
      devices:
%{ for p_index, part in partitions ~}
%{ if part.volume_group == vg.vg_name ~}
        - partition-${p_index}
%{ endif ~}
%{ endfor ~}
      preserve: false

%{ for lv in vg.partitions ~}
    # Logical Volume: ${lv.lv_name}
    - id: lv-${lv.lv_name}
      type: lvm_partition
      name: ${lv.lv_name}
      volgroup: volgroup-${vg.vg_name}
%{ if lv.size != -1 ~}
      size: ${lv.size}M
%{ else ~}
      size: ${lv.size}
%{ endif ~}

    # 8. Format LV lv-${lv.lv_name}
    - id: format-${lv.lv_name}
      type: format
      volume: lv-${lv.lv_name}
      label: ${lv.format.label}
      fstype: ${lv.format.fstype}

    # 9. Mount ${lv.lv_name}
    - id: mount-${lv.lv_name}
      type: mount
      path: ${lv.mount.path == "" ? "none" : lv.mount.path}
      device: format-${lv.lv_name}
%{ if lv.mount.options != "" ~}
      options: ${lv.mount.options}
%{ endif ~}
%{ endfor ~}
%{ endfor ~}
%{ endif ~}
