
// BLOCK: locals
// Define local build variables
// ref: https://github.com/vmware-samples/packer-examples-for-vsphere/blob/main/builds/windows/server/2019/windows-server.pkr.hcl
// ref: https://www.hashicorp.com/blog/using-template-files-with-hashicorp-packer

locals {
  data_source_content = {
    "autounattend.xml" = templatefile(var.answerfile_file_path, merge(var, local))
  }
  boot_command = [
    "${var.vm_boot_command}"
  ]
  iso_paths = [
    "[${var.vm_iso_datastore}] ${var.iso_base_dir}/${var.iso_dir}/${var.iso_file}",
    "[] /vmimages/tools-isoimages/${var.vm_guest_os_family}.iso"
  ]
  scripts = [
    "_common/scripts/${var.vm_guest_os_family}/windows-prepare.ps1",
    "_common/scripts/${var.vm_guest_os_family}/downloadandinstallcertificate.ps1",
    "_common/scripts/${var.vm_guest_os_family}/ConfigureRemotingForAnsible.ps1"
  ]
  inline = [
    "Get-EventLog -LogName * | ForEach { Clear-EventLog -LogName $_.Log }"
  ]

  vm_shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c Packer_Provisioning_Shutdown"

}
