common_data_source="disk"
answerfile_file_path="autounattend.xml.pkrtpl.hcl"
iso_base_dir="iso-repos"
ip_settle_timeout="1m"
compression_level="6"
disk_adapter_type="sata"
vm_boot_command="<spacebar>"
vm_communicator="winrm"
vm_template_host="esx02.dettonville.int"
vm_template_host2="esx01.dettonville.int"
vm_disk_size="40000"
vm_disk_controller_type="pvscsi"
vm_firmware="efi-secure"
vm_firmware_alt="bios"
vm_cdrom_type="sata"
vm_guest_os_type="windows2019srv_64Guest"
vm_guest_os_family="windows"
vm_network_card_e1000="e1000"
vm_network_card="vmxnet3"
vm_mem_reserve_all="true"
vm_boot_wait="3s"
vm_inst_os_language="en-US"
vm_inst_os_keyboard="en-US"