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

# All generated input variables will be of 'string' type as this is how Packer JSON
# views them; you can change their type later on. Read the variables type
# constraints documentation
# https://www.packer.io/docs/templates/hcl_templates/variables#type-constraints for more info.
variable "ansible_bitbucket_ssh_key_string" {
  type      = string
  default   = "${env("ANSIBLE_BITBUCKET_SSH_KEY_STRING")}"
  sensitive = true
}

variable "ansible_command" {
  type    = string
  default = "env PATH=$PATH:~/.venv/ansible/bin PYTHONUNBUFFERED=1 ansible-playbook"
}

variable "ansible_command_orig" {
  type    = string
  default = "ansible-playbook"
}

variable "ansible_command_orig2" {
  type    = string
  default = "env PATH=$PATH:~/.local/bin ANSIBLE_REMOTE_TEMP=/var/tmp/packer-provisioner-ansible-local PYTHONUNBUFFERED=1 ansible-playbook"
}

variable "ansible_command_orig3" {
  type    = string
  default = "env PATH=$PATH:~/.local/bin PYTHONUNBUFFERED=1 ansible-playbook"
}

variable "ansible_fetch_images_playbook" {
  type    = string
  default = "ansible/fetch_os_images.yml"
}

variable "ansible_galaxy_command" {
  type    = string
  default = "env PATH=$PATH:~/.venv/ansible/bin ansible-galaxy"
}

variable "ansible_galaxy_command_orig" {
  type    = string
  default = "ansible-galaxy"
}

variable "ansible_galaxy_command_orig2" {
  type    = string
  default = "ANSIBLE_COLLECTIONS_PATHS=./collections ansible-galaxy"
}

variable "ansible_galaxy_command_orig3" {
  type    = string
  default = "PATH=$PATH:~/.local/bin ansible-galaxy"
}

variable "ansible_galaxy_command_orig4" {
  type    = string
  default = "env PATH=$PATH:~/.local/bin ANSIBLE_COLLECTIONS_PATHS=$ANSIBLE_COLLECTIONS_PATH:./collections ansible-galaxy"
}

variable "ansible_galaxy_command_orig5" {
  type    = string
  default = "env PATH=$PATH:~/.local/bin ansible-galaxy"
}

variable "ansible_galaxy_req_file" {
  type    = string
  default = "../ansible/roles/requirements.packer.yml"
}

variable "ansible_inventory_file" {
  type    = string
  default = "../ansible/inventory/xenv_hosts.yml"
}

variable "ansible_inventory_group_vars" {
  type    = string
  default = "../ansible/inventory/group_vars"
}

variable "ansible_playbook_dir" {
  type    = string
  default = "../ansible"
}

variable "ansible_playbook_file" {
  type    = string
  default = "../ansible/bootstrap_vm_template.yml"
}

variable "ansible_playbook_tag" {
  type    = string
  default = "vm-template"
}

variable "ansible_playbook_vault" {
  type    = string
  default = "./vars/vault.yml"
}

variable "ansible_playbook_vault_password_file" {
  type    = string
  default = "~/.vault_pass"
}

variable "ansible_staging_directory" {
  type    = string
  default = "/var/tmp/packer-provisioner-ansible-local"
}

variable "ansible_staging_directory_orig" {
  type    = string
  default = "/tmp/packer-provisioner-ansible-local"
}

variable "ansible_vault_password" {
  type      = string
  default   = "${env("ANSIBLE_VAULT_PASSWORD")}"
  sensitive = true
}

variable "answerfile_file_path" {
  type    = string
  default = "kickstart.cfg"
}

variable "answerfile_file_path_orig" {
  type    = string
  default = "kickstart.cfg"
}

variable "auto_build" {
  type    = string
  default = "True"
}

variable "box_name" {
  type    = string
  default = "vmlinux"
}

variable "box_tag" {
  type    = string
  default = ""
}

variable "build_format" {
  type    = string
  default = "hcl"
}

variable "build_git_commit_hash" {
  type    = string
  default = "${env("GIT_COMMIT")}"
}

variable "build_job_id" {
  type    = string
  default = "${env("BUILD_ID")}"
}

variable "build_job_url" {
  type    = string
  default = "${env("BUILD_URL")}"
}

variable "build_on_error" {
  type    = string
  default = "abort"
}

variable "build_organization" {
  type    = string
  default = "Dettonville"
}

variable "build_password" {
  type      = string
  default   = "${env("PACKER_USER_PASSWORD")}"
  sensitive = true
}

variable "build_username" {
  type      = string
  default   = "${env("PACKER_USER_USERNAME")}"
  sensitive = true
}

variable "builder_type" {
  type    = string
  default = "vsphere-iso"
}

variable "cert_url_endpoint" {
  type    = string
  default = "https://gitea.admin.dettonville.int"
}

variable "common_data_source" {
  type    = string
  default = "disk"
}

variable "common_vm_version" {
  type    = string
  default = "17"
}

variable "common_vm_version_orig" {
  type    = string
  default = "20"
}

variable "compression_level" {
  type    = string
  default = "6"
}

variable "data_source_command" {
  type    = string
  default = ""
}

variable "description" {
  type    = string
  default = "Linux VM"
}

variable "disk_adapter_type" {
  type    = string
  default = "scsi"
}

variable "fetch_os_image" {
  type    = string
  default = "False"
}

variable "import_ovf_to_dc2" {
  type    = string
  default = "false"
}

variable "inspec_timeout" {
  type    = string
  default = "50m"
}

variable "ip_settle_timeout" {
  type    = string
  default = "5s"
}

variable "ip_wait_timeout" {
  type    = string
  default = "60m"
}

variable "iso_base_dir" {
  type    = string
  default = "iso-repos/linux"
}

variable "iso_checksum" {
  type    = string
  default = ""
}

variable "iso_checksum_orig" {
  type    = string
  default = ""
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_dir" {
  type    = string
  default = ""
}

variable "iso_file" {
  type    = string
  default = ""
}

variable "iso_url" {
  type    = string
  default = ""
}

variable "iso_url_jigdo" {
  type    = string
  default = ""
}

variable "iso_url_save" {
  type    = string
  default = ""
}

variable "os_image_dir" {
  type    = string
  default = "/data/datacenter/jenkins/osimages"
}

variable "pause_before_inspec" {
  type    = string
  default = "360s"
}

variable "pip_version" {
  type    = string
  default = "latest"
}

variable "qemu_accelerator" {
  type    = string
  default = "kvm"
}

variable "skip_packer_build" {
  type    = string
  default = "false"
}

variable "ssh_handshake_attempts" {
  type    = string
  default = "20"
}

variable "ssh_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ssh_pty" {
  type    = string
  default = "false"
}

variable "ssh_timeout" {
  type    = string
  default = "60m"
}

variable "ssh_username" {
  type      = string
  default   = ""
  sensitive = true
}

variable "temporary_key_pair_type" {
  type    = string
  default = "ed25519"
}

variable "vagrant_cloud_token" {
  type    = string
  default = ""
}

variable "vagrant_cloud_username" {
  type    = string
  default = ""
}

variable "vcenter_cluster" {
  type    = string
  default = "Management"
}

variable "vcenter_cluster_root_folder" {
  type    = string
  default = "/dettonville-dc-01/vm"
}

variable "vcenter_datacenter" {
  type    = string
  default = "dettonville-dc-01"
}

variable "vcenter_host" {
  type    = string
  default = "vcenter7.dettonville.int"
}

variable "vcenter_host2" {
  type    = string
  default = "vcenter7.site2.dettonville.int"
}

variable "vcenter_password" {
  type      = string
  default   = "${env("VMWARE_VCENTER_PASSWORD")}"
  sensitive = true
}

variable "vcenter_username" {
  type    = string
  default = "${env("VMWARE_VCENTER_USERNAME")}"
}

variable "vm_boot_command" {
  type    = string
  default = ""
}

variable "vm_boot_command_orig" {
  type    = string
  default = ""
}

variable "vm_boot_command_postfix" {
  type    = string
  default = ""
}

variable "vm_boot_command_prefix" {
  type    = string
  default = ""
}

variable "vm_boot_http_directory" {
  type    = string
  default = "http"
}

variable "vm_boot_keygroup_interval" {
  type    = string
  default = "20ms"
}

variable "vm_boot_order" {
  type    = string
  default = "cdrom,disk,ethernet0"
}

variable "vm_boot_order_install" {
  type    = string
  default = "cdrom,disk"
}

variable "vm_boot_wait" {
  type    = string
  default = "5s"
}

variable "vm_build_env" {
  type    = string
  default = "na"
}

variable "vm_build_folder" {
  type    = string
  default = "TemplateBuildAutomation/builds"
}

variable "vm_build_tag" {
  type    = string
  default = "${env("BUILD_TAG")}"
}

variable "vm_cdrom_remove" {
  type    = string
  default = "true"
}

variable "vm_cdrom_type" {
  type    = string
  default = "sata"
}

variable "vm_communicator" {
  type    = string
  default = "ssh"
}

variable "vm_cpu_cores_num" {
  type    = string
  default = "1"
}

variable "vm_cpu_hot_plug" {
  type    = string
  default = "true"
}

variable "vm_cpu_max_num" {
  type    = string
  default = "4"
}

variable "vm_cpu_num" {
  type    = string
  default = "2"
}

variable "vm_data_dir" {
  type    = string
  default = "/data/datacenter/vmware"
}

variable "vm_datastore" {
  type    = string
  default = "nfs_ds1"
}

variable "vm_deploy_folder" {
  type    = string
  default = "TemplateBuildAutomation"
}

variable "vm_disk_controller_type" {
  type    = string
  default = "pvscsi"
}

variable "vm_disk_device" {
  type    = string
  default = "sda"
}

variable "vm_disk_partition_auto" {
  type    = string
  default = "false"
}

variable "vm_disk_size" {
  type    = string
  default = "40000"
}

variable "vm_disk_thin_provisioned" {
  type    = string
  default = "false"
}

variable "vm_disk_use_swap" {
  type    = string
  default = "true"
}

variable "vm_firmware" {
  type    = string
  default = "efi-secure"
}

variable "vm_firmware_alt" {
  type    = string
  default = "bios"
}

variable "vm_firmware_alt2" {
  type    = string
  default = "efi-secure"
}

variable "vm_firmware_alt3" {
  type    = string
  default = "efi"
}

variable "vm_guest_os_edition_datacenter" {
  type    = string
  default = "datacenter"
}

variable "vm_guest_os_edition_standard" {
  type    = string
  default = "standard"
}

variable "vm_guest_os_experience_core" {
  type    = string
  default = "core"
}

variable "vm_guest_os_experience_desktop" {
  type    = string
  default = "dexp"
}

variable "vm_guest_os_family" {
  type    = string
  default = ""
}

variable "vm_guest_os_keyboard" {
  type    = string
  default = "us"
}

variable "vm_guest_os_language" {
  type    = string
  default = "en_US"
}

variable "vm_guest_os_timezone" {
  type    = string
  default = "UTC"
}

variable "vm_guest_os_type" {
  type    = string
  default = ""
}

variable "vm_host" {
  type    = string
  default = "esx02.dettonville.int"
}

variable "vm_inst_os_image" {
  type    = string
  default = ""
}

variable "vm_inst_os_image_datacenter_core" {
  type    = string
  default = "Windows Server 2019 SERVERDATACENTERCORE"
}

variable "vm_inst_os_image_datacenter_desktop" {
  type    = string
  default = "Windows Server 2019 SERVERDATACENTER"
}

variable "vm_inst_os_image_standard_core" {
  type    = string
  default = "Windows Server 2019 SERVERSTANDARDCORE"
}

variable "vm_inst_os_image_standard_desktop" {
  type    = string
  default = "Windows Server 2019 SERVERSTANDARD"
}

variable "vm_inst_os_keyboard" {
  type    = string
  default = "en-US"
}

variable "vm_inst_os_kms_key" {
  type    = string
  default = ""
}

variable "vm_inst_os_kms_key_datacenter" {
  type    = string
  default = ""
}

variable "vm_inst_os_kms_key_standard" {
  type    = string
  default = ""
}

variable "vm_inst_os_language" {
  type    = string
  default = "en-US"
}

variable "vm_iso_datastore" {
  type    = string
  default = "nfs_ds1"
}

variable "vm_mem_hot_plug" {
  type    = string
  default = "true"
}

variable "vm_mem_reserve_all" {
  type    = string
  default = "false"
}

variable "vm_mem_size" {
  type    = string
  default = "2048"
}

variable "vm_network" {
  type    = string
  default = "BridgedNetwork"
}

variable "vm_network_card" {
  type    = string
  default = "vmxnet3"
}

variable "vm_network_card_e1000" {
  type    = string
  default = "e1000"
}

variable "vm_network_device" {
  type    = string
  default = "ens192"
}

variable "vm_network_mgt" {
  type    = string
  default = "VM Network"
}

variable "vm_network_mgt_orig" {
  type    = string
  default = "Management Network"
}

variable "vm_network_orig" {
  type    = string
  default = "VM Network"
}

variable "vm_shutdown_command" {
  type    = string
  default = ""
}

variable "vm_shutdown_timeout" {
  type    = string
  default = "15m"
}

variable "vm_template_build_folder" {
  type    = string
  default = "/dettonville-dc-01/vm/TemplateBuildAutomation/builds"
}

variable "vm_template_build_name" {
  type    = string
  default = "vm-template"
}

variable "vm_template_build_type" {
  type    = string
  default = ""
}

variable "vm_template_datastore" {
  type    = string
  default = "nfs_ds1"
}

variable "vm_template_deploy_folder" {
  type    = string
  default = "/dettonville-dc-01/vm/TemplateBuildAutomation"
}

variable "vm_template_dir" {
  type    = string
  default = "/data/datacenter/vmware/templates"
}

variable "vm_template_host" {
  type    = string
  default = "esx02.dettonville.int"
}

variable "vm_template_name" {
  type    = string
  default = "vmtemplate"
}

variable "vm_template_root_folder" {
  type    = string
  default = "/dettonville-dc-01/vm/TemplateBuildAutomation"
}

variable "vm_template_type" {
  type    = string
  default = ""
}

variable "vmware_iso_nfs_local_mounted" {
  type    = string
  default = "false"
}

variable "win_guest_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "win_guest_password_save" {
  type    = string
  default = "VMware1!"
}

variable "win_guest_username" {
  type    = string
  default = ""
}

variable "winrm_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "winrm_username" {
  type    = string
  default = ""
}