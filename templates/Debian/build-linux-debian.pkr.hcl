
// BLOCK: locals
// Define local build variables
// ref: https://github.com/vmware-samples/packer-examples-for-vsphere/blob/main/builds/linux/rhel/9/linux-rhel.pkr.hcl
// ref: https://www.hashicorp.com/blog/using-template-files-with-hashicorp-packer

locals {

  //additional_packages = ["git", "make", "vim"]
  additional_packages = [
    "openssh-server",
    "bc",
    "lsb-release",
    "wget",
    "curl",
    "rsync",
    "git",
    "jq",
    "python3",
    "python3-pip",
    "python3-apt",
    "python3-virtualenv",
    "python3-venv"
  ]

  // Additional Settings

  data_source_content = {
    "/preseed.cfg" = templatefile(var.answerfile_file_path, {
      build_username           = var.build_username
      build_password           = var.build_password
      build_ssh_public_key     = var.build_ssh_public_key
      build_password_encrypted = local.build_password_encrypted
      vm_disk_device           = local.vm_disk_device
      vm_firmware              = var.vm_firmware
      vm_guest_os_language     = var.vm_guest_os_language
      vm_guest_os_keyboard     = var.vm_guest_os_keyboard
      vm_guest_os_timezone     = var.vm_guest_os_timezone
      vm_guest_os_cloudinit    = var.vm_guest_os_cloudinit
      vm_network_device        = var.vm_network_device
      common_data_source       = var.common_data_source
      network = templatefile("${abspath(path.root)}/_templates/network.pkrtpl.hcl", {
        device  = var.vm_network_device
        ip      = var.vm_ip_address
        netmask = var.vm_ip_netmask
        gateway = var.vm_ip_gateway
        dns     = var.vm_dns_list
        hostname = var.vm_template_name
        domain  = var.vm_network_domain
      })
      storage = templatefile("${abspath(path.root)}/_templates/storage.pkrtpl.hcl", {
        firmware   = var.vm_firmware
        device     = local.vm_disk_device
        swap       = local.vm_disk_use_swap
        partitions = local.vm_disk_configs[var.vm_template_type].vm_disk_partitions
        lvm        = local.vm_disk_configs[var.vm_template_type].vm_disk_lvm
      })
      additional_packages = join(" ", local.additional_packages)
    })
  }

  data_source_command = var.common_data_source == "http" ? "ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/preseed.cfg\"" : "file=/media/preseed.cfg"
  mount_cdrom_command = "mkdir -p /media && mount -t iso9660 /dev/sr1 /media"
  mount_cdrom         = var.common_data_source == "http" ? " " : local.mount_cdrom_command

  // ref: https://github.com/hashicorp/packer-plugin-vmware/issues/64#issuecomment-1436174305
  vm_boot_command = [
    // This waits for 3 seconds, sends the "c" key, and then waits for another 3 seconds. In the GRUB boot loader, this is used to enter command line mode.
    "<wait3s>c<wait3s>",
    // 1. Load Linux kernel AND all boot arguments on one line
    "linux /install.amd/vmlinuz ",
    "auto=true priority=critical ",
    "preseed/${local.data_source_command} ",
    "preseed/early_command=\"${local.mount_cdrom_command}\" ",
    "--- quiet<enter>",
    // 2. Load the initrd
    "initrd /install.amd/initrd.gz<enter>",
    // 3. Actually start the boot process
    "boot<enter>"
  ]

  iso_paths = [
    "[${var.vm_iso_datastore}] ${var.iso_base_dir}/${var.iso_dir}/${var.iso_file}"
  ]

  vm_shutdown_command = "echo '${var.build_password}' | sudo -S -E shutdown -P now"

  vm_disk_configs  = {
    small = {
      vm_disk_partitions = []
      vm_disk_lvm = []
    }
    medium = {
      vm_disk_partitions = [
        {
          pv_name = "boot-efi",
          volume_group = "",
          drive = "sda",
          size = 1024,
          format = {
            label  = "EFIFS",
            fstype = "efi",
          },
          mount = {
            path    = "/boot/efi",
            options = "",
          }
        },
        {
          // /boot partition
          pv_name = "boot",
          volume_group = "",
          drive = "sda",
          size = 1024,
          format = {
              label  = "BOOTFS",
              fstype = "xfs"
          },
          mount = {
              path    = "/boot",
              options = ""
          }
        },
        {
          pv_name = "pv.01",
          volume_group = "vg_root",
          drive = "sda",
          size = -1,
          format = {
            label  = "",
            fstype = ""
          },
          mount = {
            path    = "",
            options = ""
          }
        },
      ],
      vm_disk_lvm = [
        {
          vg_name = "vg_root",
          pv_name = "pv.01",
          partitions: [
            {
              lv_name = "lv_swap",
              size = 4000,
              format = {
                label  = "SWAPFS",
                fstype = "swap",
              },
              mount = {
                path    = "",
                options = "",
              }
            },
            {
              lv_name = "lv_root",
              size = 10000,
              format = {
                label  = "ROOTFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/",
                options = "",
              }
            },
            {
              lv_name = "lv_var",
              size = 8000,
              format = {
                label  = "VARFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/var",
                options = "",
              }
            },
            {
              lv_name = "lv_tmp",
              size = 4000,
              format = {
                label  = "TMPFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/tmp",
                options = "",
              }
            },
            {
              lv_name = "lv_home",
              size = 4000,
              format = {
                label  = "HOMEFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/home",
                options = "",
              }
            },
            {
              lv_name = "lv_opt",
              size = 6000,
              format = {
                label  = "OPTFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/opt",
                options = "nodev",
              }
            },
            {
              lv_name = "lv_log",
              size = 2000,
              format = {
                label  = "LOGFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/var/log",
                options = "",
              }
            },
            {
              lv_name = "lv_audit",
              size = 4096,
              format = {
                label  = "AUDITFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/var/log/audit",
                options = "nodev,noexec,nosuid",
              }
            },
          ],
        }
      ]
    }
    large = {
      vm_disk_partitions = [
        {
          pv_name = "",
          volume_group = "",
          drive = "sda",
          size = 1024,
          format = {
            label  = "EFIFS",
            fstype = "efi",
          },
          mount = {
            path    = "/boot/efi",
            options = "",
          }
        },
        {
          pv_name = "boot",
          volume_group = "",
          drive = "sda",
          size = 1024,
          format = {
            label  = "BOOTFS",
            fstype = "ext4",
          },
          mount = {
            path    = "/boot",
            options = "",
          }
        },
        {
          pv_name = "pv.01",
          volume_group = "vg_root",
          drive = "sda",
          size = -1,
          format = {
            label  = "",
            fstype = "",
          },
          mount = {
            path    = "",
            options = "",
          }
        },
        {
          pv_name = "pv.02",
          drive = "sda",
          size = 24000,
          format = {
            label  = "",
            fstype = "",
          },
          mount = {
            path    = "",
            options = "",
          }
        },
      ],
      vm_disk_lvm = [
        {
          vg_name = "vg_root",
          pv_name = "pv.01",
          partitions : [
            {
              lv_name = "lv_swap",
              size    = 12000,
              format  = {
                label  = "SWAPFS",
                fstype = "swap",
              },
              mount = {
                path    = "",
                options = "",
              }
            },
            {
              lv_name = "lv_root",
              size    = 30000,
              format  = {
                label  = "ROOTFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/",
                options = "",
              }
            },
            {
              lv_name = "lv_var",
              size    = 24000,
              format  = {
                label  = "VARFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/var",
                options = "",
              }
            },
            {
              lv_name = "lv_tmp",
              size    = 12000,
              format  = {
                label  = "TMPFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/tmp",
                options = "",
              }
            },
            {
              lv_name = "lv_home",
              size    = 12000,
              format  = {
                label  = "HOMEFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/home",
                options = "nodev,nosuid",
              }
            },
            {
              lv_name = "lv_opt",
              size    = 18000,
              format  = {
                label  = "OPTFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/opt",
                options = "nodev",
              }
            },
            {
              lv_name = "lv_log",
              size    = 6000,
              format  = {
                label  = "LOGFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/var/log",
                options = "nodev,noexec,nosuid",
              }
            },
            {
              lv_name = "lv_audit",
              size    = 12000,
              format  = {
                label  = "AUDITFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/var/log/audit",
                options = "nodev,noexec,nosuid",
              }
            },
          ],
        },
        {
          vg_name = "vg_data",
          pv_name = "pv.02",
          partitions: [
            {
              lv_name = "lv_data",
              size = 24000,
              format = {
                label  = "DATAFS",
                fstype = "xfs",
              },
              mount = {
                path    = "/data",
                options = "nodev",
              }
            }
          ]
        }
      ]
    }
  }

  // VM Storage Settings
  vm_disk_device     = "sda"
  vm_disk_use_swap   = true
}
