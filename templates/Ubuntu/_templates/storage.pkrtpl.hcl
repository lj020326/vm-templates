storage:
%{ if partitions == [] ~}
  swap:
    size: 0
  layout:
    name: lvm
%{ else ~}
  config:
    # 1. Define the physical disk
    - id: disk-${device}
      type: disk
      path: /dev/${device}
      ptable: gpt
      preserve: false
      wipe: superblock-recursive

%{ for index, partition in partitions ~}
    # 2. Partition partition-${index}
    - id: partition-${index}
      type: partition
      device: disk-${device}
      size: ${partition.size == -1 ? "-1" : "${partition.size}M"}
      number: ${index}
%{ if firmware == "bios" && index == 0 ~}
      flag: bios_grub
%{ else ~}
%{ if firmware != "bios" && partition.mount.path == "/boot/efi" ~}
      flag: boot
%{ else ~}
%{ if partition.mount.path == "/boot" ~}
      flag: boot
%{ endif ~}
%{ endif ~}
%{ endif ~}
%{ if index == 0 ~}
      grub_device: true
%{ endif ~}

%{ if partition.format.fstype != "" ~}
    # 3. Format the partition
    - id: format-part-${index}
      type: format
      volume: partition-${index}
      label: ${partition.format.label}
      fstype: ${partition.format.fstype}
%{ endif ~}

%{ if partition.volume_group == "" ~}
    # 4. Mount the partition
    - id: mount-part-${index}
      type: mount
      path: ${partition.mount.path == "" ? "none" : partition.mount.path}
      device: format-part-${index}
%{ if partition.mount.options != "" ~}
      options: ${partition.mount.options}
%{ endif ~}
%{ endif ~}
%{ endfor ~}

%{ for vg_index, volume_group in lvm ~}
    # 6. LVM Volume Group ${vg_index}
    - id: volgroup-${volume_group.vg_name}
      type: lvm_volgroup
      name: ${volume_group.vg_name}
      devices:
%{ for p_index, partition in partitions ~}
%{ if partition.volume_group == volume_group.vg_name ~}
        - partition-${p_index}
%{ endif ~}
%{ endfor ~}
      preserve: false

%{ for lv_index, lv in volume_group.partitions ~}
    # 7. Logical Volume for ${volume_group.vg_name}
    - id: lv-${lv.lv_name}
      type: lvm_partition
      name: ${lv.lv_name}
      volgroup: volgroup-${volume_group.vg_name}
%{ if lv.size != -1 ~}
      size: ${lv.size}M
%{ else ~}
      size: ${lv.size}
%{ endif ~}

    # 8. Format ${volume_group.vg_name} LV
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
