
Table of Contents:

* [VM Template Build Automation Configuration](#vm-template-build-automation-configuration)
  * [Template Build Variable Overview](#template-build-variable-overview)
  * [Configuration Variables](#configuration-variables)
     * [[1] Common Template Build Settings/Configurations](#1-common-template-build-settingsconfigurations)
       * [[1.1] Data Sources](#11-data-sources)
       * [[1.2] Ansible Settings](#12-ansible-settings)
       * [[1.3] VMware vSphere](#13-vmware-vsphere)
     * [[2] Distribution-Specific Settings/Configurations](#2-distribution-specific-settingsconfigurations)
     * [[3] Release-Specific Settings/Configurations](#3-release-specific-settingsconfigurations)
     * [[4] Flavor/Type-Specific Settings/Configurations](#4-flavortype-specific-settingsconfigurations)
       * [[4.1] RHEL Examples](#41-rhel-examples)
       * [[4.2] Windows Examples](#42-windows-examples)
     * [[5] Environment-Specific Settings/Configurations](#5-environment-specific-settingsconfigurations)
       * [[5.1] Environment Examples](#51-environment-examples)
  * [Parameterized Platform OS Answer Files](#parameterized-platform-os-answer-files)
  * [Usage](#usage)
    * [Building distribution](#building-distribution)
    * [Using pre-built template for VM instance creation](#using-pre-built-template-for-vm-instance-creation)
  * [Using Packer Commands](#using-packer-commands)
    * [Upgrading json formatted inputs to new HCL2 format](#upgrading-json-formatted-inputs-to-new-hcl2-format)
    * [Running packer build for RHEL](#running-packer-build-for-rhel)
    * [Running packer build for Windows](#running-packer-build-for-windows)
    * [Running packer validate for RHEL](#running-packer-validate-for-rhel)
    * [Running packer validate for Windows](#running-packer-validate-for-windows)

# VM Template Build Automation Configuration<a name="vm-template-build-automation-configuration"></a>

## Template Build Variable Overview<a name="template-build-variable-overview"></a>

This repo includes variables files that can be used to configure customized platform OS template configurations.

The [variables][packer-variables] are defined in `.json` and `.pkrvars.hcl` files.

Running the config script `./templates/config.sh`:
1) synchronizes/converts the json config files to HCL2 formatted variable files `.pkrvars.hcl` files in the respective common/distribution/release directories as well as 
2) creates the necessary symlinks to each distribution directory.

```shell
$ git clone https://github.com/lj020326/vm-templates.git
$ cd vm-templates
$ templates/config.sh
```

## Configuration Variables<a name="configuration-variables"></a>

Variables can be set for template build settings/configs related to:
  1) common build settings:
     - [`templates/common-vars.json`](../templates/common-vars.json)
  2) distribution specific settings:
     - [`templates/RHEL/distribution-vars.json`](../templates/RHEL/distribution-vars.json)
     - [`templates/Windows/distribution-vars.json`](../templates/Windows/distribution-vars.json)
  3) release specific settings
     - [`templates/RHEL/8/template.json`](../templates/RHEL/8/template.json)
     - [`templates/RHEL/8/template.json`](../templates/RHEL/8/template.json)
     - [`templates/Windows/2019/template.json`](../templates/Windows/2019/template.json)
     - [`templates/Windows/2022/template.json`](../templates/Windows/2022/template.json)
  4) flavor/type specific settings
     - [`templates/RHEL/8/box_info.small.json`](../templates/RHEL/8/box_info.small.json)
     - [`templates/RHEL/8/box_info.medium.json`](../templates/RHEL/8/box_info.medium.json)
     - [`templates/RHEL/8/box_info.large.json`](../templates/RHEL/8/box_info.large.json)
     - [`templates/RHEL/9/box_info.small.json`](../templates/RHEL/9/box_info.small.json)
     - [`templates/RHEL/9/box_info.medium.json`](../templates/RHEL/9/box_info.medium.json)
     - [`templates/RHEL/9/box_info.large.json`](../templates/RHEL/9/box_info.large.json)
     - [`templates/Windows/2019/box_info.standard.json`](../templates/Windows/2019/box_info.standard.json)
     - [`templates/Windows/2019/box_info.datacenter.json`](../templates/Windows/2019/box_info.datacenter.json)
     - [`templates/Windows/2019/box_info.sqlserver.json`](../templates/Windows/2019/box_info.sqlserver.json)
     - [`templates/Windows/2019/box_info.desktop.json`](../templates/Windows/2019/box_info.desktop.json)
     - [`templates/Windows/2022/box_info.standard.json`](../templates/Windows/2022/box_info.standard.json)
     - [`templates/Windows/2022/box_info.datacenter.json`](../templates/Windows/2022/box_info.datacenter.json)
     - [`templates/Windows/2022/box_info.sqlserver.json`](../templates/Windows/2022/box_info.sqlserver.json)
     - [`templates/Windows/2022/box_info.desktop.json`](../templates/Windows/2022/box_info.desktop.json)
  5) environment specific settings
     - [`templates/env-vars.SANDBOX.json`](../templates/env-vars.SANDBOX.json)
     - [`templates/env-vars.DEV.json`](../templates/env-vars.DEV.json)
     - [`templates/env-vars.PROD.json`](../templates/env-vars.PROD.json)

All of the `.json` variable files are converted to HCL2 formatted `.pkr.hcl` files by the aforementioned `templates/config.sh` script.

Upon editing/updating any of the above `.json` make sure to re-run the `templates/config.sh` to make sure the updates are reflected in the corresponding hcl files. 

### [1] Common Template Build Settings/Configurations<a name="1-common-template-build-settingsconfigurations"></a>

Edit the `templates/common-vars.json` file to configure the following common variables:

- Virtual Machine Settings
- Template and Content Library Settings
- OVF Export Settings
- Removable Media Settings
- Boot and Provisioning Settings
- HCP Packer Registry

templates/common-vars.json:
```json
{
  "variables": {
    "auto_build": "True",
    "box_name": "vmlinux",
    "box_tag": "",
    "build_format": "hcl",
    "build_username": "{{ env `PACKER_USER_USERNAME` }}",
    "build_password": "{{ env `PACKER_USER_PASSWORD` }}",
    "build_job_url": "{{ env `BUILD_URL` }}",
    "build_job_id": "{{ env `BUILD_ID` }}",
    "build_git_commit_hash": "{{ env `GIT_COMMIT` }}",
    "build_on_error": "abort",
    "builder_type": "vsphere-iso",
    "common_data_source": "disk",
    "common_vm_version": "20",
    "fetch_os_image": "False",
    "data_source_command": "",
    "vmware_iso_nfs_local_mounted": "false",
    "cert_url_endpoint": "https://gitea.admin.dettonville.int",
    "compression_level": "6",
    "description": "Linux VM",
    "disk_adapter_type": "scsi",
    "inspec_timeout": "50m",
    "ip_settle_timeout": "5s",
    "ip_settle_timeout_bad": "1m",
    "ip_settle_timeout_default": "5s",
    "ip_wait_timeout_default": "30m",
    "ip_wait_timeout": "60m",
    "iso_base_dir": "iso-repos/linux",
    "iso_dir": "",
    "iso_file": "",
    "iso_url": "",
    "iso_checksum": "",
    "iso_checksum_type": "sha256",
    "answerfile_file_path": "kickstart.cfg",
    "os_image_dir": "/data/datacenter/jenkins/osimages",
    ...
  }
}
```

#### [1.1] Data Sources<a name="11-data-sources"></a>

The default provisioning data source for Linux machine image builds is `disk`. This is used to serve the OS-specific answer file (e.g., kickstart.cfg (RHEL), autounattend.xml (Windows)) files to the Linux/Windows guest operating system during the build.  If the distribution and/or release does not support the CD kickstart convention, then packer can be configured to automatically start a built-in http server to offer the kickstart configuration over http.  To use this method, change the `common_data_source` to 'http'.

Using the `disk` convention for answer files is useful for environments that may not be able to route back to the system from which Packer is running. For example, building a machine image in VMware Cloud on AWS, or running packer from a container instance (docker, openshift, etc).

```json
{
  "variables": {
    ...
    "common_data_source": "disk",
    ...
  }
}
```

The Packer `vsphere-iso` plugin `cd_content` option is used when selecting `disk` unless the distribution does not support a secondary CD-ROM. For distributions that do not support a secondary CD-ROM the `floppy_content` option is used.

#### [1.2] Ansible Settings<a name="12-ansible-settings"></a>

Edit the `templates/common-vars.json` file to configure the settings for the Ansible provisioning on Linux machine images.

templates/common-vars.json:
```json
{
  "variables": {
    ...
    "ansible_command": "env PATH=$PATH:~/.venv/ansible/bin PYTHONUNBUFFERED=1 ansible-playbook",
    "ansible_galaxy_command": "env PATH=$PATH:~/.venv/ansible/bin ansible-galaxy",
    "ansible_galaxy_req_file": "../ansible/develop-lj/ansible-linux/collections/requirements.packer.yml",
    "ansible_inventory_group_vars": "../ansible/inventory/group_vars",
    "ansible_inventory_file": "../ansible/inventory/xenv_groups.yml",
    "ansible_playbook_dir": "../ansible/develop-lj/ansible-linux",
    "ansible_playbook_file": "../ansible/develop-lj/ansible-linux/bootstrap_vm_template.yml",
    "ansible_playbook_tag": "vm-template",
    "ansible_playbook_vault": "./vars/vault.yml",
    "ansible_playbook_vault_password_file": "~/.vault_pass",
    "ansible_staging_directory": "/var/tmp/packer-provisioner-ansible-local",
    "ansible_vault_password": "{{ env `ANSIBLE_VAULT_PASSWORD` }}"
  }
}
```

#### [1.3] VMware vSphere<a name="13-vmware-vsphere"></a>

Edit the `templates/common-vars.json` file to configure the following:

- vSphere Endpoint and Credentials
- vSphere Settings


templates/common-vars.json:
```json
{
  "variables": {
    ...
    "vcenter_host": "vcenter7.dettonville.int",
    "vcenter_host2": "vcenter7.site2.dettonville.int",
    "vcenter_username": "{{ env `VMWARE_VCENTER_USERNAME` }}",
    "vcenter_password": "{{ env `VMWARE_VCENTER_PASSWORD` }}",
    "vcenter_datacenter": "DFW",
    "vcenter_cluster": "NONPROD-OS",
    "vcenter_cluster_root_folder": "/DFW/vm",
    "vm_host": "esx02.dettonville.int",
    ...
  }
}
```


### [2] Distribution-Specific Settings/Configurations<a name="2-distribution-specific-settingsconfigurations"></a>

Edit the `templates/<distribution>/distribution-vars.json` file in each distribution folder to configure __distribution-specific settings__ such as the following:

- vcenter_cluster `(string)`
- vm_guest_os_family `(string)`
- vm_boot_command_prefix `(string)`
- vm_boot_command_postfix `(string)`
- vm_boot_wait `(time interval)`
- vm_communicator `(string)`
- vm_host `(string)`
- vm_template_host `(string)`
- vm_template_host2 `(string)`
- vm_disk_controller_type `(string)`
- vm_firmware `(string)`
- vm_network_card `(string)`
- vm_shutdown_timeout `(time interval)`


Example: templates/RHEL/distribution-vars.json:
```json
{
  "vcenter_cluster": "LINUX",
  "common_data_source": "disk",
  "vm_boot_command_prefix": "<tab> inst.text",
  "vm_boot_command_postfix": "<wait><enter>",
  "vm_boot_wait": "5s",
  "vm_communicator": "ssh",
  "vm_template_host": "esx02.dettonville.int",
  "vm_template_host2": "esx01.dettonville.int",
  "vm_disk_controller_type": "lsilogic",
  "vm_network_card": "vmxnet3",
  "vm_shutdown_timeout": "15m",
  "vm_guest_os_family": "linux",
  "vm_firmware": "bios"
}
```

Note in the prior RHEL example, the parameter value for `vcenter_cluster` has been designated for the linux RHEL distributions as `LINUX`.

This can be set to specific values for each distribution.

For example, for the windows distributions, to set the parameter value for `vcenter_cluster` to `NONPROD-OS`, the following can be specified:

Example: templates/Windows/distribution-vars.json:
```json
{
  "vcenter_cluster": "NONPROD-OS",
  "common_data_source": "disk",
  "answerfile_file_path": "autounattend.xml.pkrtpl.hcl",
  "compression_level": "6",
  "disk_adapter_type": "sata",
  "vm_boot_command": "<spacebar>",
  "vm_boot_wait": "3s",
  "vm_communicator": "winrm",
  "vm_disk_size": "40000",
  "vm_disk_controller_type": "pvscsi",
  "vm_firmware_alt": "efi-secure",
  "vm_firmware": "bios",
  "vm_cdrom_type": "sata",
  "vm_guest_os_type": "windows2019srv_64Guest",
  "vm_guest_os_family": "windows",
  "vm_network_card_e1000": "e1000",
  "vm_network_card": "vmxnet3",
  "vm_mem_reserve_all": "true",
  "vm_inst_os_language": "en-US",
  "vm_inst_os_keyboard": "en-US"
}
```

### [3] Release-Specific Settings/Configurations<a name="3-release-specific-settingsconfigurations"></a>

Edit the `templates/<distribution>/<release>/template.json` file in each distribution folder to configure __release-specific settings__ such as the following:

- answerfile_file_path `(string)` - release-specific answerfile
- iso_checksum_type `(string)`
- iso_checksum `(string)`
- iso_url `(string)`
- vm_inst_os_image `(string)`
- vm_boot_wait `(time interval)`
- vm_guest_os_type `(string)`

RHEL Example: templates/RHEL/9/template.json:
```json
{
  "answerfile_file_path": "./templates/ks9.cfg.pkrtpl.hcl",
  "iso_checksum_type": "sha256",
  "iso_url": "https://archiva.admin.dettonville.int/repository/internal/org/dettonville/infra/rhel/rhel-9.2-x86_64-dvd.iso",
  "iso_checksum": "a18bf014e2cb5b6b9cee3ea09ccfd7bc2a84e68e09487bb119a98aa0e3563ac2",
  "vm_boot_command_prefix": "<up><wait><tab>",
  "vm_guest_os_type": "rhel9_64Guest"
}
```

Windows Example: templates/Windows/2022/template.json:
```json
{
  "answerfile_file_path": "./2022/templates/autounattend.xml.pkrtpl.hcl",
  "iso_checksum_type": "sha1",
  "iso_checksum": "5caaad8e9d4f36caa7a61633ea572bddc88fa1bd",
  "iso_url": "https://archiva.admin.dettonville.int/repository/internal/org/dettonville/infra/windows/windows-SRV2022.LTSC.21H2.Build-20348.1006.iso",
  "vm_inst_os_image": "Windows Server 2022 SERVERSTANDARDCORE",
  "vm_guest_os_type": "windows2019srvNext_64Guest"
}
```

### [4] Flavor/Type-Specific Settings/Configurations<a name="4-flavortype-specific-settingsconfigurations"></a>

Edit the `templates/<distribution>/<release>/box_info.<flavor/type>.json` file to configure the following virtual machine hardware settings, as required:

- vm_mem_size `(int)`
- vm_disk_size `(int)`
- vm_cpu_num `(int)`
- vm_cpu_cores_num `(int)`
- vm_template_type `(string)`
- box_name `(string)`
- box_tag `(string)`
- description `(string)`

#### [4.1] RHEL Examples<a name="41-rhel-examples"></a>

RHEL Example: templates/RHEL/9/box_info.small.json:
```json
{
  "vm_mem_size": "2000",
  "vm_disk_size": "20000",
  "vm_cpu_num": "2",
  "vm_cpu_cores_num": "1",
  "vm_template_type": "small",
  "vm_disk_partition_auto": "true",
  "box_name": "redhat9-small",
  "box_tag": "dettonville/redhat9-small",
  "description": "RedHat 9 - small template"
}
```

RHEL Example: templates/RHEL/9/box_info.large.json:
```json
{
  "vm_mem_size": "64000",
  "vm_disk_size": "140000",
  "vm_cpu_num": "4",
  "vm_cpu_cores_num": "2",
  "vm_template_type": "large",
  "box_name": "redhat9-large",
  "box_tag": "dettonville/redhat9-large",
  "description": "RedHat 9 - large template"
}
```

#### [4.2] Windows Examples<a name="42-windows-examples"></a>

Windows Example: templates/Windows/2022/box_info.standard.json:
```json
{
  "vm_inst_os_image": "Windows Server 2022 SERVERSTANDARDCORE",
  "vm_inst_os_kms_key": "VDYBN-27WPP-V4HQT-9VMD4-VMK7H",
  "vm_mem_size": "2000",
  "vm_disk_size": "20000",
  "vm_cpu_num": "2",
  "vm_cpu_cores_num": "1",
  "auto_build": "True",
  "box_name": "windows2022",
  "box_tag": "dettonville/windows2022",
  "description": "Windows 2022 Server"
}
```

Windows Example: templates/Windows/2022/box_info.datacenter.json:
```json
{
  "vm_inst_os_image": "Windows Server 2022 SERVERDATACENTERCORE",
  "vm_inst_os_kms_key": "WX4NM-KYWYW-QJJR4-XV3QB-6VM33",
  "vm_mem_size": "64000",
  "vm_disk_size": "140000",
  "vm_cpu_num": "4",
  "vm_cpu_cores_num": "2",
  "box_name": "windows2022",
  "box_tag": "dettonville/windows2022",
  "description": "Windows 2022 Server"
}
```

### [5] Environment-Specific Settings/Configurations<a name="5-environment-specific-settingsconfigurations"></a>

Edit the `templates/env-vars.<environment>.json` file to configure the following settings, as required:

- vm_deploy_folder `(string)`
- vm_template_deploy_folder `(string)`
- vm_template_deploy_folder2 `(string)`
- ansible_inventory_group_vars `(string)`
- ansible_inventory_file `(string)`
- ansible_playbook_dir `(string)`
- ansible_playbook_file `(string)`
- import_ovf_to_dc2 `(boolean)`


#### [5.1] Environment Examples<a name="51-environment-examples"></a>

DEV Example: templates/env-vars.DEV.json:
```json
{
  "vm_deploy_folder": "TemplateBuildAutomation/DEV",
  "vm_template_deploy_folder": "/dettonville-dc-01/vm/TemplateBuildAutomation/DEV"
}
```

PROD Example: templates/env-vars.PROD.json:
```json
{
  "vm_deploy_folder": "TemplateBuildAutomation/PROD",
  "vm_template_deploy_folder": "/dettonville-dc-01/vm/TemplateBuildAutomation/PROD"
}
```

## Parameterized Platform OS Answer Files<a name="parameterized-platform-os-answer-files"></a>

Answer files for each platform OS have been setup as templates that can make use of the variables mentioned in the prior sections to further customize each template build. 

The Platform OS answer file details:

| OS Platform Distribution | release | answer file                                                                                                                             |
|--------------------------|---------|-----------------------------------------------------------------------------------------------------------------------------------------|
| RHEL                     | 8       | [`templates/RHEL/templates/ks8.cfg.pkrtpl.hcl`](../templates/RHEL/templates/ks8.cfg.pkrtpl.hcl)                                           | 
| RHEL                     | 9       | [`templates/RHEL/templates/ks9.cfg.pkrtpl.hcl`](../templates/RHEL/templates/ks9.cfg.pkrtpl.hcl)                                           | 
| Windows                  | 2019    | [`templates/Windows/server/2019/templates/autounattend.xml.pkrtpl.hcl`](../templates/Windows/server/2019/templates/autounattend.xml.pkrtpl.hcl) | 
| Windows                  | 2022    | [`templates/Windows/server/2022/templates/autounattend.xml.pkrtpl.hcl`](../templates/Windows/server/2019/templates/autounattend.xml.pkrtpl.hcl) | 


## Usage<a name="usage"></a>

### Building distribution<a name="building-distribution"></a>

> NOTE: This example we will have chosen RHEL/9

```shell
$ cd templates
$ env PACKER_LOG=1 BUILD_TAG=build_vm_template-test \
  packer build \
    -only vsphere-iso.RHEL \
    -on-error=abort \
    -var-file=RHEL/distribution-vars.json.pkrvars.hcl \
    -var-file=RHEL/9/template.json.pkrvars.hcl \
    -var-file=RHEL/9/box_info.small.json.pkrvars.hcl \
    -var-file=env-vars.DEV.json.pkrvars.hcl \
    -var vm_template_build_name=vm-template-rhel9-small-dev-0204 \
    -var vm_template_build_type=small \
    -var vm_template_name=vm-template-rhel9-small-dev \
    -var vm_build_env=DEV \
    -var iso_dir=RHEL/9 \
    -var iso_file=rhel-9.2-x86_64-dvd.iso \
    RHEL/

```

Now watch your build kick off and run through the building process. Once it has
completed you will be ready to test it out.

### Using pre-built template for VM instance creation<a name="using-pre-built-template-for-vm-instance-creation"></a>

The majority of these templates are used to test [ansible-datacenter VM provisioning playbooks](https://github.com/lj020326/ansible-datacenter) using the [packer-box-templates](https://github.com/lj020326/packer-templates) repo. I would highly recommend leveraging this repo for testing ansible playbook and etc.

## Using Packer Commands<a name="using-packer-commands"></a>

Use build script to perform a VM build:

```shell
$ build_vm_template.sh
```

### Upgrading json formatted inputs to new HCL2 format<a name="upgrading-json-formatted-inputs-to-new-hcl2-format"></a>

```shell
$ packer hcl2_upgrade -with-annotations common-vars.vars.json 
$ packer hcl2_upgrade common-vars.json
$ packer hcl2_upgrade test-vars.json 
$ 
$ VARS_JSON=$(jq --argjson varInfo "$(<common-vars.json)" '.variables += $varInfo' -n '{variables: $varInfo }')
$ echo $VARS_JSON | packer hcl2_upgrade -with-annotations
$ echo $VARS_JSON | packer hcl2_upgrade -with-annotations -output-file=foo
```

### Running packer build for RHEL<a name="running-packer-build-for-rhel"></a>

```shell
$ env PACKER_LOG=1 BUILD_TAG=build_vm_template-test \
  packer build \
    -only vsphere-iso.RHEL \
    -on-error=abort \
    -var-file=RHEL/distribution-vars.json.pkrvars.hcl \
    -var-file=RHEL/9/template.json.pkrvars.hcl \
    -var-file=RHEL/9/box_info.small.json.pkrvars.hcl \
    -var-file=env-vars.DEV.json.pkrvars.hcl \
    -var vm_template_build_name=vm-template-rhel9-small-dev-0204 \
    -var vm_template_build_type=small \
    -var vm_template_name=vm-template-rhel9-small-dev \
    -var vm_build_env=DEV \
    -var iso_dir=RHEL/9 \
    -var iso_file=rhel-9.2-x86_64-dvd.iso \
    RHEL/
```

### Running packer build for Windows<a name="running-packer-build-for-windows"></a>

```shell
$ env PACKER_LOG=1 BUILD_TAG=build_vm_template-test \
  packer build \
    -only vsphere-iso.Windows \
    -on-error=abort \
    -var-file=Windows/distribution-vars.json.pkrvars.hcl \
    -var-file=Windows/2022/template.json.pkrvars.hcl \
    -var-file=Windows/2022/box_info.standard.json.pkrvars.hcl \
    -var-file=env-vars.DEV.json.pkrvars.hcl \
    -var vm_template_build_name=vm-template-windows2022-standard-dev-0028 \
    -var vm_template_build_type=standard \
    -var vm_template_name=vm-template-windows2022-standard-dev \
    -var vm_build_env=DEV \
    -var iso_dir=windows/2022 \
    -var iso_file=windows-SRV2022.LTSC.21H2.Build-20348.1006.iso \
    Windows/
```

### Running packer validate for RHEL<a name="running-packer-validate-for-rhel"></a>

```shell
$ packer validate \
    -only vsphere-iso.RHEL \
    -on-error=abort \
    -var-file=RHEL/distribution-vars.json.pkrvars.hcl \
    -var-file=RHEL/9/template.json.pkrvars.hcl \
    -var-file=RHEL/9/box_info.small.json.pkrvars.hcl \
    -var-file=env-vars.DEV.json.pkrvars.hcl \
    -var vm_template_build_name=vm-template-rhel9-small-dev-0204 \
    -var vm_template_build_type=small \
    -var vm_template_name=vm-template-rhel9-small-dev \
    -var vm_build_env=DEV \
    -var iso_dir=RHEL/9 \
    -var iso_file=rhel-9.2-x86_64-dvd.iso \
    RHEL/
```

### Running packer validate for Windows<a name="running-packer-validate-for-windows"></a>

```shell
$ packer validate \
    -only vsphere-iso.Windows \
    -on-error=abort \
    -var-file=Windows/distribution-vars.json.pkrvars.hcl \
    -var-file=Windows/2022/template.json.pkrvars.hcl \
    -var-file=Windows/2022/box_info.standard.json.pkrvars.hcl \
    -var-file=env-vars.DEV.json.pkrvars.hcl \
    -var vm_template_build_name=vm-template-windows2022-standard-dev-0028 \
    -var vm_template_build_type=standard \
    -var vm_template_name=vm-template-windows2022-standard-dev \
    -var vm_build_env=DEV \
    -var iso_dir=windows/2022 \
    -var iso_file=windows-SRV2022.LTSC.21H2.Build-20348.1006.iso \
    Windows/

ssh ${BUILD_USERNAME}@10.10.100.173
ssh ${BUILD_USERNAME}@10.10.100.73
```

## Reference<a name="reference"></a> 

- https://github.com/vmware-samples
- https://github.com/vmware-samples/packer-examples-for-vsphere
- https://www.hashicorp.com/blog/using-template-files-with-hashicorp-packer
- https://github.com/chef/bento
- https://github.com/burkeazbill/ubuntu-22-04-packer-fusion-workstation/blob/master/http/user-data
- https://github.com/williamsanmartin/packer-template-ubuntu/blob/main/http/user-data
- [vagrant-box-templates](https://github.com/mrlesmithjr/vagrant-box-templates)
- https://github.com/mwrock/packer-templates
- https://github.com/jacqinthebox/packer-templates
- https://github.com/geerlingguy/packer-boxes
- 


[//]: Links
[packer-variables]: https://developer.hashicorp.com/packer/docs/templates/hcl_templates/variables
[vmware-pvscsi]: https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.hostclient.doc/GUID-7A595885-3EA5-4F18-A6E7-5952BFC341CC.html
[vmware-vmxnet3]: https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.vm_admin.doc/GUID-AF9E24A8-2CFA-447B-AC83-35D563119667.html
