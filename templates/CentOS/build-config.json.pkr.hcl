# This file was autogenerated by the 'packer hcl2_upgrade' command. We
# recommend double checking that everything is correct before going forward. We
# also recommend treating this file as disposable. The HCL2 blocks in this
# file can be moved to other files. For example, the variable blocks could be
# moved to their own 'variables.pkr.hcl' file, etc. Those files need to be
# suffixed with '.pkr.hcl' to be visible to Packer. To use multiple files at
# once they also need to be in the same folder. 'packer inspect folder/'
# will describe to you what is in that folder.

# Avoid mixing go templating calls ( for example ```{{ upper(`string`) }}``` )
# and HCL2 calls (for example '${ var.string_value_example }' ). They won't be
# executed together and the outcome will be unknown.

# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "qemu" "CentOS" {
  accelerator            = "${var.qemu_accelerator}"
  boot_command           = ["<tab> ${var.boot_command_prefix}=http://{{ .HTTPIP }}:{{ .HTTPPort }}/centos/ks.cfg <enter><wait>"]
  boot_wait              = "${var.vm_boot_wait}"
  cpus                   = "${var.vm_cpu_num}"
  disk_interface         = "virtio"
  disk_size              = "${var.vm_disk_size}"
  format                 = "qcow2"
  headless               = true
  http_directory         = "${var.vm_boot_http_directory}"
  iso_checksum           = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url                = "${var.iso_url}"
  memory                 = "${var.vm_mem_size}"
  output_directory       = "output-${var.vm_template_build_name}-${build.type}-${local.timestamp}"
  shutdown_command       = "echo '${var.ssh_password}'| sudo -S /sbin/halt -h -p"
  ssh_handshake_attempts = "20"
  ssh_password           = "${var.ssh_password}"
  ssh_timeout            = "${var.ssh_timeout}"
  ssh_username           = "${var.ssh_username}"
  vm_name                = "${var.vm_template_build_name}"
}

source "virtualbox-iso" "CentOS" {
  boot_command           = ["<tab> ${var.boot_command_prefix}=http://{{ .HTTPIP }}:{{ .HTTPPort }}/centos/ks.cfg <enter><wait>"]
  boot_wait              = "${var.vm_boot_wait}"
  cpus                   = "${var.vm_cpu_num}"
  disk_size              = "${var.vm_disk_size}"
  guest_os_type          = "RedHat_64"
  hard_drive_interface   = "${var.disk_adapter_type}"
  headless               = true
  http_directory         = "${var.vm_boot_http_directory}"
  iso_checksum           = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url                = "${var.iso_url}"
  memory                 = "${var.vm_mem_size}"
  output_directory       = "output-${var.vm_template_build_name}-${build.type}-${local.timestamp}"
  shutdown_command       = "echo '${var.ssh_password}'| sudo -S /sbin/halt -h -p"
  ssh_handshake_attempts = "20"
  ssh_password           = "${var.ssh_password}"
  ssh_timeout            = "${var.ssh_timeout}"
  ssh_username           = "${var.ssh_username}"
  vm_name                = "${var.vm_template_build_name}"
}

source "vmware-iso" "CentOS" {
  boot_command           = ["<tab> ${var.boot_command_prefix}=http://{{ .HTTPIP }}:{{ .HTTPPort }}/centos/ks.cfg <enter><wait>"]
  boot_wait              = "${var.vm_boot_wait}"
  cpus                   = "${var.vm_cpu_num}"
  disk_adapter_type      = "${var.disk_adapter_type}"
  disk_size              = "${var.vm_disk_size}"
  disk_type_id           = 0
  guest_os_type          = "centos-64"
  headless               = true
  http_directory         = "${var.vm_boot_http_directory}"
  iso_checksum           = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url                = "${var.iso_url}"
  memory                 = "${var.vm_mem_size}"
  output_directory       = "output-${var.vm_template_build_name}-${build.type}-${local.timestamp}"
  shutdown_command       = "echo '${var.ssh_password}'| sudo -S /sbin/halt -h -p"
  ssh_handshake_attempts = "20"
  ssh_password           = "${var.ssh_password}"
  ssh_timeout            = "${var.ssh_timeout}"
  ssh_username           = "${var.ssh_username}"
  tools_upload_flavor    = "linux"
  vm_name                = "${var.vm_template_build_name}"
  vmx_data = {
    "ethernet0.pciSlotNumber" = "32"
  }
  vmx_remove_ethernet_interfaces = true
}

source "vsphere-iso" "CentOS" {
  CPUs                   = "${var.vm_cpu_num}"
  RAM                    = "${var.vm_mem_size}"
  RAM_reserve_all        = false
  boot_command           = ["${var.boot_command_prefix}=http://{{ .HTTPIP }}:{{ .HTTPPort }}/centos/${var.kickstart_cfg}<enter><wait>"]
  boot_keygroup_interval = "${var.vm_boot_keygroup_interval}"
  boot_order             = "${var.vm_boot_order_install}"
  boot_wait              = "${var.vm_boot_wait}"
  cluster                = "${var.vcenter_cluster}"
  communicator           = "ssh"
  configuration_parameters = {
    "bios.bootDelay" = "5000"
    bootOrder        = "${var.vm_boot_order}"
  }
  convert_to_template  = true
  datacenter           = "${var.vcenter_datacenter}"
  datastore            = "${var.vm_datastore}"
  disk_controller_type = ["${var.vm_disk_type}"]
  firmware             = "${var.vm_firmware}"
  folder               = "${var.vm_build_folder}"
  guest_os_type        = "${var.vm_guest_os_type}"
  host                 = "${var.vm_host}"
  http_directory       = "${var.vm_boot_http_directory}"
  insecure_connection  = "true"
  ip_settle_timeout    = "${var.ip_settle_timeout}"
  ip_wait_timeout      = "${var.ip_wait_timeout}"
  iso_checksum         = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_paths            = ["[${var.vm_iso_datastore}] ${var.iso_base_dir}/${var.iso_dir}/${var.iso_file}"]
  network_adapters {
    network      = "${var.vm_network_mgt}"
    network_card = "${var.vm_network_card}"
  }
  notes                  = "Build via Packer - date: ${timestamp()} build tag: ${var.vm_build_tag}"
  password               = "${var.vcenter_password}"
  shutdown_command       = "echo '${var.ssh_password}'| sudo -S /sbin/halt -h -p"
  shutdown_timeout       = "15m"
  ssh_handshake_attempts = "${var.ssh_handshake_attempts}"
  ssh_password           = "${var.ssh_password}"
  ssh_pty                = "${var.ssh_pty}"
  ssh_timeout            = "${var.ssh_timeout}"
  ssh_username           = "${var.ssh_username}"
  storage {
    disk_size             = "${var.vm_disk_size}"
    disk_thin_provisioned = "${var.vm_disk_thin_provisioned}"
  }
  username       = "${var.vcenter_username}"
  vcenter_server = "${var.vcenter_host}"
  vm_name        = "${var.vm_template_build_name}"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.qemu.CentOS", "source.virtualbox-iso.CentOS", "source.vmware-iso.CentOS", "source.vsphere-iso.CentOS"]

  provisioner "shell" {
    execute_command = "echo '${var.ssh_username}' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts         = ["_common/scripts/install_site_cacerts.sh"]
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_username}' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts         = ["_common/scripts/base.sh", "_common/scripts/vmware.sh", "_common/scripts/sshd.sh"]
  }

  provisioner "shell" {
    environment_vars = ["PIP_VERSION=${var.pip_version}", "VENV_DIR=${var.python_venv_dir}", "ANSIBLE_VAULT_PASS=${var.ansible_vault_password}"]
    execute_command  = "echo '${var.ssh_username}' | {{ .Vars }} bash '{{ .Path }}'"
    scripts          = ["_common/scripts/ansible.sh"]
  }

  provisioner "ansible-local" {
    clean_staging_directory = "false"
    command                 = "${var.ansible_command}"
    extra_arguments         = ["--tag", "${var.ansible_playbook_tag}", "--vault-password-file=${var.ansible_playbook_vault_password_file}", "-e", "@${var.ansible_playbook_vault}"]
    galaxy_command          = "${var.ansible_galaxy_command}"
    galaxy_file             = "${var.ansible_galaxy_req_file}"
    group_vars              = "${var.ansible_inventory_group_vars}"
    inventory_file          = "${var.ansible_inventory_file}"
    playbook_dir            = "${var.ansible_playbook_dir}"
    playbook_file           = "${var.ansible_playbook_file}"
    staging_directory       = "${var.ansible_staging_directory}"
  }

  provisioner "shell" {
    execute_command   = "echo '${var.ssh_username}' | {{ .Vars }} sudo -H -S -E bash '{{ .Path }}'"
    expect_disconnect = "true"
    script            = "_common/scripts/reboot.sh"
    skip_clean        = "true"
  }

  provisioner "inspec" {
    extra_arguments = ["--no-distinct-exit"]
    inspec_env_vars = ["CHEF_LICENSE=accept"]
    pause_before    = "1m0s"
    profile         = "../inspec"
    timeout         = "1h0m0s"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_username}' | {{ .Vars }} sudo -H -S -E bash '{{ .Path }}'"
    scripts         = ["_common/scripts/cleanup.sh", "_common/scripts/zerodisk.sh"]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
