  ## ref: https://askubuntu.com/questions/1235529/server-autoinstall-how-to-customise-storage-section
  ## ref: https://askubuntu.com/questions/1415360/ubuntu-22-04-autoinstall-storage-section-autoinstall-config-did-not-create-ne
  ## ref: https://linuxconfig.org/how-to-write-and-perform-ubuntu-unattended-installations-with-autoinstall
  ## ref: https://www.golinuxcloud.com/uefi-pxe-boot-server-ubuntu-20-04-cloud-init/
  ## ref: https://www.molnar-peter.hu/en/ubuntu-jammy-netinstall-pxe.html
  storage:
    ## ref: https://askubuntu.com/questions/1415360/ubuntu-22-04-autoinstall-storage-section-autoinstall-config-did-not-create-ne
    ## ref: https://gist.github.com/anedward01/b68e00bb2dcfa4f1335cd4590cbc8484
    ## ref: https://gist.github.com/cyrenity/24ae7da9a214d255025d048b660b56c3
    config:
      # Partition table
      - id: disk-${device}
        type: disk
        path: /dev/${device}
        name: ''
        ptable: gpt
        preserve: false
        grub_device: true
        wipe: superblock-recursive
#        wipe: superblock

      # Linux boot partition
      - id: partition-0
        type: partition
        device: disk-${device}
        number: 1
        flag: bios_grub
#        size: 1G
        size: 1MB

      # Partition for LVM, VG
      - id: partition-1
        type: partition
        device: disk-${device}
        number: 2
        size: -1
#        preserve: false
#        grub_device: false
#        wipe: superblock

      - id: lvm_volgroup-0
        name: ubuntu-vg
        devices:
          - partition-1
        preserve: false
        type: lvm_volgroup

      # LV for root
      - id: lvm_partition-0
        name: ubuntu-lv
        volgroup: lvm_volgroup-0
        size: -1
        wipe: superblock
        preserve: false
        type: lvm_partition

      - id: lvm_part0-fs
        type: format
        fstype: ext4
        volume: lvm_partition-0
        preserve: false
        label: root

      # Mount points
      - id: lvm_part0-fs-mount0
        type: mount
        path: /
        device: lvm_part0-fs

    # Swapfile on root volume
    swap:
      swap: 1G
