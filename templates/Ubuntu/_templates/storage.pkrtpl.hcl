  storage:
%{ if partitions==[] }
    swap:
      size: 0
    layout:
      name: lvm
%{ else }
    config:
      - id: disk
        type: disk
        path: /dev/${device}
        ptable: gpt
%{ for index, partition in partitions ~}
      - id: partition-${partition.pv_name}
        type: partition
        device: disk
%{ if partition.size != -1 ~}
        size: ${partition.size}M
%{ else ~}
        size: ${partition.size}
%{ endif ~}
%{ if partition.mount.path == "/boot" ~}
        flag: bios_grub
%{ endif ~}
%{ if partition.mount.path == "/boot/efi" ~}
        flag: boot
%{ endif ~}
%{ if index == 0 ~}
        grub_device: true
%{ endif ~}
%{ if partition.format.fstype != "" ~}
      - id: format-${partition.pv_name}
        type: format
        volume: partition-${partition.pv_name}
        label: ${partition.format.label}
        fstype: ${partition.format.fstype}
%{ endif ~}
%{ if partition.volume_group == "" ~}
      - id: mount-${partition.pv_name}
        type: mount
%{ if partition.mount.path == "" ~}
        path: none
%{ else ~}
        path: ${partition.mount.path}
%{ endif ~}
        device: format-${partition.pv_name}
%{ if partition.mount.options != "" ~}
        options: ${partition.mount.options}
%{ endif ~}
%{ endif ~}
%{ endfor ~}
%{ for index, volume_group in lvm ~}
      - id: volgroup-${volume_group.name}
        type: lvm_volgroup
        name: ${volume_group.name}
        devices:
%{ for index, partition in partitions ~}
%{ if partition.volume_group == volume_group.vg_name ~}
          - partition-${partition.volume_group}
%{ endif ~}
%{ endfor ~}
%{ for index, partition in volume_group.partitions ~}
      - id: partition-${volume_group.vg_name}
        type: lvm_partition
        name: ${partition.lv_name}
%{ if partition.size != -1 ~}
        size: ${partition.size}M
%{ else ~}
        size: ${partition.size}
%{ endif ~}
        volgroup: volgroup-${volume_group.vg_name}
      - id: format-${partition.lv_name}
        type: format
        volume: partition-${partition.vg_name}
        label: ${partition.format.label}
        fstype: ${partition.format.fstype}
      - id: mount-${partition.lv_name}
        type: mount
%{ if partition.mount.path == "" ~}
        path: none
%{ else ~}
        path: ${partition.mount.path}
%{ endif ~}
        device: format-${partition.lv_name}
%{ if partition.mount.options != "" ~}
        options: ${partition.mount.options}
%{ endif ~}
%{ endfor ~}
%{ endfor ~}
%{ endif ~}
