//  BLOCK: packer
//  The Packer configuration.
//  ref: https://github.com/vmware-samples/packer-examples-for-vsphere/

packer {
  required_version = ">= 1.9.4"
  required_plugins {
    git = {
      source  = "github.com/ethanmdavidson/git"
      version = ">= 0.4.3"
    }
    inspec = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/inspec"
    }
    windows-update = {
      source  = "github.com/rgl/windows-update"
      version = ">= 0.14.3"
    }
  }
}

//  BLOCK: data
//  Defines the data sources.

data "git-repository" "cwd" {}

// BLOCK: locals
// Define local build variables
// ref: https://github.com/vmware-samples/packer-examples-for-vsphere/blob/main/builds/linux/rhel/9/linux-rhel.pkr.hcl

locals {
  build_password_encrypted   = bcrypt(var.build_password)
  build_version              = data.git-repository.cwd.head
  build_date                 = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  build_notes                = "Build via Packer - date: ${local.build_date} build tag: ${var.vm_build_tag}"

  ssh_username = var.build_username
  ssh_password = var.build_password
  winrm_username = var.build_username
  winrm_password = var.build_password
  win_guest_username = var.build_username
  win_guest_password = var.build_password

  iso_checksum = "${var.iso_checksum_type}:${var.iso_checksum}"

  vm_disk_partition_list = []
}

//variable "vm_disk_partitions" {
//  type = list(object({
//    name = string
//    size = number
//    format = object({
//      label  = string
//      fstype = string
//    })
//    mount = object({
//      path    = string
//      options = string
//    })
//    volume_group = string
//  }))
//  description = "The disk partitions for the virtual disk."
//  default     = []
//}
//
//variable "vm_disk_lvm" {
//  type = list(object({
//    name = string
//    partitions = list(object({
//      name = string
//      size = number
//      format = object({
//        label  = string
//        fstype = string
//      })
//      mount = object({
//        path    = string
//        options = string
//      })
//    }))
//  }))
//  description = "The LVM configuration for the virtual disk."
//  default     = []
//}


// Additional Settings

variable "additional_packages" {
  type        = list(string)
  description = "Additional packages to install."
  default     = []
}

