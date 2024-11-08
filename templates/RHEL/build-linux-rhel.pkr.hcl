
// BLOCK: locals
// Define local build variables
// ref: https://github.com/vmware-samples/packer-examples-for-vsphere/blob/main/builds/linux/rhel/9/linux-rhel.pkr.hcl
// ref: https://www.hashicorp.com/blog/using-template-files-with-hashicorp-packer

locals {

  //additional_packages = ["git", "make", "vim"]
  additional_packages = [
    "python3.8",
    "open-vm-tools",
    "virt-who",
    "gcc",
    "kernel-devel",
    "kernel-headers",
    "make",
    "python3",
    "vim",
    "curl",
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
      network                  = templatefile("${abspath(path.root)}/templates/network.pkrtpl.hcl", merge(var, local))
      storage = templatefile("${abspath(path.root)}/templates/storage.pkrtpl.hcl", {
        device     = local.vm_disk_device
        swap       = local.vm_disk_use_swap
        partitions = local.vm_disk_configs[var.vm_template_type].vm_disk_partitions
        lvm        = local.vm_disk_configs[var.vm_template_type].vm_disk_lvm
      })
      additional_packages = join(" ", local.additional_packages)
    })
  }

  data_source_command = var.common_data_source == "http" ? "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart.cfg" : "inst.ks=cdrom:/kickstart.cfg"

  vm_boot_command = [
    // This sends the "up arrow" key, typically used to navigate through boot menu options.
    "<up>",
    // This sends the "e" key. In the GRUB boot loader, this is used to edit the selected boot menu option.
    "e",
    // This sends two "down arrow" keys, followed by the "end" key, and then waits. This is used to navigate to a specific line in the boot menu option's configuration.
    "<down><down><end><wait>",
    // This types the string "text" followed by the value of the 'data_source_command' local variable.
    // This is used to modify the boot menu option's configuration to boot in text mode and specify the kickstart data source configured in the common variables.
    "inst.text ${local.data_source_command}",
    // This sends the "enter" key, waits, turns on the left control key, sends the "x" key, and then turns off the left control key. This is used to save the changes and exit the boot menu option's configuration, and then continue the boot process.
    "<enter><wait><leftCtrlOn>x<leftCtrlOff>"
  ]

  iso_paths = [
    "[${var.vm_iso_datastore}] ${var.iso_base_dir}/${var.iso_dir}/${var.iso_file}"
  ]

  vm_shutdown_command = "echo '${var.build_password}' | sudo -S /sbin/halt -h -p"

  vm_disk_configs  = {
    small = {
      vm_disk_partitions = []
      vm_disk_lvm = []
    }
    medium = {
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
          pv_name = "",
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
