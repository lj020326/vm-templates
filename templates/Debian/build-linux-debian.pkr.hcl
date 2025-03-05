
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
    "jq"
  ]

  // Additional Settings

  data_source_content = {
    "/kickstart.cfg" = templatefile(var.answerfile_file_path, {
      build_username           = var.build_username
      build_password           = var.build_password
      build_ssh_public_key     = var.build_ssh_public_key
      build_password_encrypted = local.build_password_encrypted
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
        device     = local.vm_disk_device
        swap       = local.vm_disk_use_swap
        partitions = local.vm_disk_configs[var.vm_template_type].vm_disk_partitions
        lvm        = local.vm_disk_configs[var.vm_template_type].vm_disk_lvm
      })
      additional_packages = join(" ", local.additional_packages)
    })
  }

  data_source_command = var.common_data_source == "http" ? "ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/kickstart.cfg\"" : "ds=nocloud"
//  data_source_command = var.common_data_source == "http" ? "ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/kickstart.cfg\"" : "ds=nocloud file=hd:sr1:/kickstart.cfg"
  mount_cdrom_command = "<leftAltOn><f2><leftAltOff> <enter><wait> mount /dev/sr1 /media<enter> <leftAltOn><f1><leftAltOff>"
  mount_cdrom         = var.common_data_source == "http" ? " " : local.mount_cdrom_command

  // ref: https://github.com/hashicorp/packer-plugin-vmware/issues/64#issuecomment-1436174305
  vm_boot_command = [
    // This waits for 3 seconds, sends the "c" key, and then waits for another 3 seconds. In the GRUB boot loader, this is used to enter command line mode.
    "<wait3s>c<wait3s>",
    // This types a command to load the Linux kernel from the specified path.
    "linux /install.amd/vmlinuz",
    // This types a string that sets the auto-install/enable option to true. This is used to automate the installation process.
    " auto-install/enable=true",
    // This types a string that sets the debconf/priority option to critical. This is used to minimize the number of questions asked during the installation process.
    " debconf/priority=critical",
    // This types the value of the 'data_source_command' local variable. This is used to specify the kickstart data source configured in the common variables.
    " ${local.data_source_command}",
    // This types a string that sets the noprompt option and then sends the "enter" key. This is used to prevent the installer from pausing for user input.
    " noprompt --<enter>",
    // This types a command to load the initial RAM disk from the specified path and then sends the "enter" key.
    "initrd /install.amd/initrd.gz<enter>",
    // This types the "boot" command and then sends the "enter" key. This starts the boot process using the loaded kernel and initial RAM disk.
    "boot<enter><wait3s>",
    // This waits for 30 seconds. This is typically used to give the system time to boot before sending more commands.
    "<wait40s>",
    // This types the value of the `mount_cdrom` local variable. This is used to mount the installation preseed/kickstart media on cdrom2 (/dev/sr2).
    " ${local.mount_cdrom}",
    "<wait3s>",
    "file:///media/kickstart.cfg",
    "<enter>"
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
          drive = "sda",
          size = 1024,
          format = {
            label  = "BOOTFS",
            fstype = "xfs",
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
