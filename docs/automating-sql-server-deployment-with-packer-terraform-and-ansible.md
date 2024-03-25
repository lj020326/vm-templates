
# Automating SQL Server Deployment with Packer, Terraform and Ansible

Equinox uses Microsoft SQL Server as the primary relational database for our services, applications, and tools. This translates to many SQL servers, in multiple environments which over time has resulted in server sprawl and configuration drift. This is a common occurrence when processes are manual, policies are not enforced, and drift is not remedied regularly.

To simplify the environments and reduce costs, we made it a priority to adopt configuration management practices that were both repeatable and shareable. Here we describe the new process for building our SQL Servers in AWS using Packer, Terraform, and Ansible.

## Background

Our engineering team launched an initiative to identify redundancies, deprecate obsolete databases, consolidate servers, modernize application versions, and enable high availability and disaster recovery. For the infrastructure team, this presented an opportunity to implement configuration management tools so that we may work to prevent future sprawl and drift. Although SQL Server and Windows servers do not generally conjure thoughts of automated deployment and configuration, we decided to take up the challenge.

## Requirements

Since the Equinox infrastructure includes hybrid of public (AWS and Azure) clouds and private (VMware vCenter) with Windows and Linux operating in each, it was important to devise a strategy that would not simply meet the needs of the SQL server deployments in AWS but could be used throughout the organization.

In AWS we wanted to begin enforcing certain standards:

-   Encryption for all EBS volumes when new instances are created
-   Consistent tags for volumes and instances
-   Uniform naming conventions for the server
-   Apply IAM Roles for access to other AWS products

Windows:

-   Consistent drive letters and labels
-   Local group management
-   Timezone settings
-   Standard software install
-   Enable the configuration management tool

SQL Server best practices:

-   Databases stored on NTFS volumes with 64k clusters.
-   Set Windows Firewall access for SQL related ports

## Packer

[Packer](https://www.packer.io/) is a tool that allows us to build custom machine images, also known as AMIs. Custom AMIs enable us to ensure that the root volume is created and encrypted with our KMS key and install base applications. Here is a sample Packer JSON file for building a custom AMI. When complete this AMI will have an encrypted root drive and be available in the AWS account.

```json
{
  "variables": {
    "aws_access_key": "{{env `AWS_ACCESS_KEY_ID`}}",
    "aws_secret_key": "{{env `AWS_SECRET_ACCESS_KEY`}}",
    "region": "us-east-1"
  },
  "builders": [
    {
      "type": "amazon-ebs",
      "access_key": "{{ user `aws_access_key` }}",
      "secret_key": "{{ user `aws_secret_key` }}",
      "region": "{{ user `region` }}",
      "instance_type": "t2.medium",
      "vpc_id": "vpc-00000000",
      "subnet_id": "subnet-00000000",
      "security_group_ids": [
        "sg-aaaaaaaa",
        "sg-bbbbbbbb"
      ],
      "source_ami_filter": {
        "filters": {
          "virtualization-type": "hvm",
          "name": "Windows_Server-2016-English-Full-Base-*",
          "root-device-type": "ebs"
        },
        "most_recent": true,
        "owners": "amazon"
      },
      "ami_name": "MY_Windows_2016_Encrypted-{{ timestamp }}",
      "encrypt_boot": true,
      "kms_key_id": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      "user_data_file": "./bootstrap_win.txt",
      "communicator": "winrm",
      "winrm_username": "Administrator",
      "winrm_password": "SecretBuildPassword",
      "launch_block_device_mappings": [
        {
          "device_name": "/dev/sda1",
          "volume_size": 75,
          "volume_type": "gp2",
          "delete_on_termination": true
        }
      ],
      "tags": {
        "Name": "MY_Windows_2016_Encrypted-{{ timestamp }}",
        "Packer": "true",
        "Instance-OS": "windows"
      }
    }
  ]
}
```

## Terraform

[Terraform](https://www.terraform.io/) is a tool that allows us to define infrastructure as code. Common tasks such as spinning up instances with the correct name, tags, volume attachments, role, type, etc. are possible with Terraform. Defining a basic config with Terraform gives us the ability with a single command to stand up the SQL service in AWS with our standards. This includes setting an IAM role, attaching encrypted drives and tagging all the AWS resources.

```hcl
resource "aws_instance" "blogsql01" {
  ami                    = "${var.my_windows_2016_ami}"
  instance_type          = "t2.large"
  availability_zone      = "us-east-1a"
  key_name               = "My_EC2_Key"
  iam_instance_profile   = "sql-server-blog"
  subnet_id              = "subnet-00000000"
  vpc_security_group_ids = ["${var.all_security_groups}"]

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = "${var.admin_password}"
  }

  provisioner "file" {
    source      = "ps1/"
    destination = "C:\\PS1\\"
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe C:\\PS1\\ConfigureRemotingForAnsible.ps1 -EnableCredSSP",
      "powershell.exe C:\\PS1\\Add-MyDomainServer.ps1",
    ]
  }

  tags {
    Name                  = "BLOGSQL01"
    Owner                 = "blog-team"
    Instance-OS           = "windows"
    Environment           = "test"
    Project-Cost          = "Tech Blog"
    Purpose               = "SQL Demo"
    sql-version           = "2017Developer"
    Terraform             = "true"
  }
}

resource "aws_ebs_volume" "blogsql01_data" {
  availability_zone = "us-east-1a"
  size              = 100
  encrypted         = true
  type              = "gp2"
  kms_key_id        = "arn:aws:kms:us-east-1:999999999999:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

  tags {
    Name        = "BLOGSQL01-xvdf-data"
    Mount       = "xvdf"
    Owner       = "blog-team"
    Purpose     = "data-drive"
    Environment = "test"
  }
}

resource "aws_ebs_volume" "blogsql01_backup" {
  availability_zone = "us-east-1a"
  size              = 50
  encrypted         = true
  type              = "gp2"
  kms_key_id        = "arn:aws:kms:us-east-1:999999999999:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

  tags {
    Name        = "BLOGSQL01-xvdg-backups"
    Mount       = "xvdg"
    Owner       = "blog-team"
    Purpose     = "backup-drive"
    Environment = "test"
  }
}

resource "aws_ebs_volume" "blogsql01_temp" {
  availability_zone = "us-east-1a"
  size              = 25
  encrypted         = true
  type              = "gp2"
  kms_key_id        = "arn:aws:kms:us-east-1:999999999999:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

  tags {
    Name        = "BLOGSQL01-xvdh-temp"
    Mount       = "xvdh"
    Owner       = "blog-team"
    Purpose     = "temp-drive"
    Environment = "test"
  }
}

resource "aws_ebs_volume" "blogsql01_logs" {
  availability_zone = "us-east-1a"
  size              = 25
  encrypted         = true
  type              = "gp2"
  kms_key_id        = "arn:aws:kms:us-east-1:999999999999:key/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

  tags {
    Name        = "BLOGSQL01-xvdh-temp"
    Mount       = "xvdh"
    Owner       = "blog-team"
    Purpose     = "temp-drive"
    Environment = "test"
  }
}
resource "aws_volume_attachment" "blogsql01_xvdf" {
  device_name = "xvdf"
  volume_id   = "${aws_ebs_volume.blogsql01_data.id}"
  instance_id = "${aws_instance.blogsql01.id}"
}

resource "aws_volume_attachment" "blogsql01_xvdg" {
  device_name = "xvdg"
  volume_id   = "${aws_ebs_volume.blogsql01_backup.id}"
  instance_id = "${aws_instance.blogsql01.id}"
}

resource "aws_volume_attachment" "blogsql01_xvdh" {
  device_name = "xvdh"
  volume_id   = "${aws_ebs_volume.blogsql01_temp.id}"
  instance_id = "${aws_instance.blogsql01.id}"
}

resource "aws_volume_attachment" "blogsql01_xvdi" {
  device_name = "xvdi"
  volume_id   = "${aws_ebs_volume.blogsql01_logs.id}"
  instance_id = "${aws_instance.blogsql01.id}"
}
```

Additional remote-exec PowerShell scripts allow us to configure the host for Ansible Remoting and to add the server to the Windows domain via a callback to the Ansible Tower. The PowerShell script to invoke the callback. The URL and host key are generated in the Ansible Tower job template:

```powershell

function CallPlaybook {
    param(
        [String]$towerurl = "https://mytowerhosts:443/api/v2/job_templates/42/callback/",
        [string]$hostkey = "abcdefghijklmnopqrstuvwxyz123456"
    )
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-RestMethod -Method POST -uri $towerurl -Body @{host_config_key=$hostkey}
        return "Rest Method Invoked"
    }
    catch {
        return "Unable to Invoke REST Method"
    }
}

CallPlaybook

```

When \`terraform apply\` is run, the following happens: a new Window Server instance is created using the custom AMI, four EBS volumes are added to the instance, the Windows server is added to the domain. After this process is complete, the Windows Server is ready for a SQL install.

## Ansible

[Ansible](https://www.ansible.com/) maintains OS and Application level settings. Roles establish the base Windows domain member settings, SQL Install, and SQL best practices.

The SQL install role uses a PowerShell script to format the SQL data drives with the correct allocation setting and set the letters and labels.

```powershell
# Recommended clustersize/Allocation units for SQL drives
$clustersize = 65536

# Hash defining standard drive letters
$drivemap = @{
    1="D"
    2="B"
    3="T"
    4="L"
}

# Hash defining standard drive labels
$labelmap = @{
    "D"="Data";
    "B"="Backup";
    "T"="TempDB";
    "L"="Logs"
}

# Pull the disk numbers from the drivemap hash
$alldisks = $drivemap.Keys

# iterate through each disk checking for correct drive format, letter, and label
foreach ($disk in $alldisks) {
    $vol = (Get-Partition -Disknumber $disk | Get-Volume)
    $drive = $drivemap.($disk)
    $label = $labelmap.($drive)
    if ($vol.AllocationUnitSize -ne $clustersize){
        Write-Host "Formatting disk $disk as NTFS with allocation unit size $clustersize and label $label"
        Get-Partition -DiskNumber $disk | Format-Volume -FileSystem NTFS -AllocationUnitSize $clustersize -NewFileSystemLabel $label
    }
    if ($vol.DriveLetter -ne $drive){
        Write-Host "Setting drive letter for disk $disk to $drive"
        Get-Partition -DiskNumber $disk | Set-Partition -NewDriveLetter $drive
    }
    if ($vol.FileSystemLabel -ne $label){
        Write-Host "Updating volume label for drive $drive to $label"
        $vol | Set-Volume -NewFileSystemLabel $label
    }
}
```

Next the PowerShell DSC module performs the SQL server install based on AWS tags. To use the Ansible Powershell DSC module, the Powershell DSC modules must be installed.

```yaml
---
- name: Powershell | Install Required Powershell Modules
  win_psmodule: name={{ item }} state=present
  with_items:
    - SQLServerDsc
    - StorageDsc
    - ServerManager
    - dbatools
    - xNetworking
```

The tasks for the SQL Server 2017 Developer Edition install look like this:

```yaml
---
#Install SQL Server 2017 Developer Edition
- name: Create temp folder
  win_file:
    path: "{{ mssql_temp_download_path }}"
    state: directory

- name: Create install folder
  win_file:
    path: "{{ mssql_installation_path }}"
    state: directory
  
- name: Fetch SQL Media Downloader
  win_get_url:
    url: "{{ mssql_installation_source }}"
    dest: "{{ mssql_temp_download_path }}\\SQLServer2017-SSEI-Dev.exe"
    force: no

- name: Use Media Downloader to fetch SQL Installation CABs to {{ mssql_installation_path }}
  win_shell: "{{ mssql_temp_download_path }}\\SQLServer2017-SSEI-Dev.exe /Action=Download /MediaPath={{ mssql_installation_path }} /MediaType=CAB /Quiet"
  args:
    creates: "{{ mssql_installation_path }}\\SQLServer2017-DEV-x64-ENU.exe"

- name: Extract Installation Media
  win_shell:  "{{ mssql_installation_path }}\\SQLServer2017-DEV-x64-ENU.exe /X:{{ mssql_installation_path }}\\Media /Q"
  args:
    creates: "{{ mssql_installation_path }}\\Media\\SETUP.EXE"

- name: Install SQL Server
  win_dsc:
    resource_name: SQLSetup
    Action: Install
    UpdateEnabled: True
    SourcePath: "{{ mssql_installation_path }}\\Media"
    InstanceName: "{{ mssql_instance_name }}"
    InstallSharedDir: "{{ mssql_installshared_path }}"
    InstallSharedwowDir: "{{ mssql_installsharedwow_path }}"
    InstanceDir: "{{ mssql_instance_path }}"
    SQLUserDBDir: "{{ mssql_sqluserdata_path }}"
    SQLUserDBLogDir: "{{ mssql_sqluserlog_path }}"
    SQLTempDBDir: "{{ mssql_sqltempDB_path }}"
    SQLTempDBLogDir: "{{ mssql_sqltempDBlog_path }}"
    Features: "{{ mssql_features }}"
    SQLCollation: "{{ mssql_collation }}"
    BrowserSvcStartupType: "{{ mssql_browsersvc_mode }}"
    SuppressReboot: "{{ mssql_suppress_reboot }}"
    SQLSysAdminAccounts: "{{ mssql_sysadmin_accounts }}"
    PsDscRunAsCredential_username: '{{ ansible_user }}'
    PsDscRunAsCredential_password: '{{ ansible_password }}'
  no_log: true
  tags: install_sql

- name: Configure the MSSQLSERVERAGENT Service
  win_service:
    name: sqlserveragent
    state: started
    username: "{{ mssql_agentsvc_account }}"
    password: "{{ mssql_agentsvc_account_pass }}"
  tags: install_sql
```

## Results

This approach has proven very successful in helping us wrangle our SQL Server infrastructure. Long gone are the days of inconsistent hand-crafted server builds. We are seeing numerous benefits such as quicker build times, increased consistency, easier non-prod refreshes, and better positioning disaster recovery.

We are just beginning our journey with Packer Terraform and Ansible, so there are numerous opportunities for optimization, portability, and integration.

## Reference

- https://eqxtech.com/engineering/automating-sql-server-deployment-with-packer-terraform-and-ansible/
