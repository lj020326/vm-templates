
// BLOCK: locals
// Define local build variables
// ref: https://github.com/vmware-samples/packer-examples-for-vsphere/blob/main/builds/linux/rhel/9/linux-rhel.pkr.hcl
// ref: https://www.hashicorp.com/blog/using-template-files-with-hashicorp-packer

locals {
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
}
