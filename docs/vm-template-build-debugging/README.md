
# How to debug a failed vm-template build

## Example 1 - failed galaxy-collections install

### Step 1 - View pipeline results

In the following example, the pipeline output shows the failed results as seen in the following image.

![pipeline failed results](./img/1-1-pipeline-fail.png)

From the pipeline output take note of the failed command for use in later step:
```output
...
11:49:39      vsphere-iso.RHEL: Executing Ansible: cd /var/tmp/packer-provisioner-ansible-local &&  env PATH=$PATH:~/.venv/ansible/bin PYTHONUNBUFFERED=1 ansible-playbook /var/tmp/packer-provisioner-ansible-local/bootstrap_vm_template.yml --extra-vars "packer_build_name=RHEL packer_builder_type=vsphere-iso packer_http_addr=172.21.33.149:8338 -o IdentitiesOnly=yes" --tag vm-template --vault-password-file=~/.vault_pass -e @./vars/vault.yml -c local -i /var/tmp/packer-provisioner-ansible-local/xenv_infra_hosts.yml
11:49:39  ==> vsphere-iso.RHEL: [DEPRECATION WARNING]: Ansible will require Python 3.8 or newer on the
11:49:39  ==> vsphere-iso.RHEL: controller starting with Ansible 2.12. Current version: 3.6.8 (default, Jan 23
11:49:39  ==> vsphere-iso.RHEL: 2023, 22:31:05) [GCC 8.5.0 20210514 (Red Hat 8.5.0-18)]. This feature will be
11:49:39  ==> vsphere-iso.RHEL: removed from ansible-core in version 2.12. Deprecation warnings can be disabled
11:49:39  ==> vsphere-iso.RHEL:  by setting deprecation_warnings=False in ansible.cfg.
11:49:39  ==> vsphere-iso.RHEL: ERROR! the role 'dcc_common.util.apply_common_groups' was not found in /var/tmp/packer-provisioner-ansible-local/roles:/var/tmp/packer-provisioner-ansible-local/roles:/var/tmp/packer-provisioner-ansible-local
11:49:39  ==> vsphere-iso.RHEL:
11:49:39  ==> vsphere-iso.RHEL: The error appears to be in '/var/tmp/packer-provisioner-ansible-local/bootstrap_vm_template.yml': line 8, column 7, but may
11:49:39  ==> vsphere-iso.RHEL: be elsewhere in the file depending on the exact syntax problem.
11:49:39  ==> vsphere-iso.RHEL:
11:49:39  ==> vsphere-iso.RHEL: The offending line appears to be:
11:49:39  ==> vsphere-iso.RHEL:
11:49:39  ==> vsphere-iso.RHEL:   roles:
11:49:39  ==> vsphere-iso.RHEL:     - role: dcc_common.util.apply_common_groups
11:49:39  ==> vsphere-iso.RHEL:       ^ here
11:49:39  ==> vsphere-iso.RHEL: Error executing Ansible: Non-zero exit status: 1
11:49:39  ==> vsphere-iso.RHEL: Step "StepProvision" failed, aborting...
...
```

It is apparent that the VM template build pipeline failed at the `ansible-playbook` after successfully creating the VM from the kickstart. 

Take note of the command (reformatted) to be used later to debug the issue:
```shell
$ cd /var/tmp/packer-provisioner-ansible-local && \
$ export PATH=$PATH:~/.venv/ansible/bin
$ ansible-playbook bootstrap_vm_template.yml --tag vm-template --vault-password-file=~/.vault_pass -e @./vars/vault.yml -c local -i xenv_infra_hosts.yml  

```

### Step 2 - View running VM details in vcenter

The VM created from the failed build is left still running in order to debug.

In vcenter the running VM details can be found in the template build directory `DFW/Templates/pipeline-auto-builds` as seen in the following image.

![pipeline failed results](./img/1-2-vcenter-vm-details.png)

Take note of the VM IP address to be used in the next step as `172.31.26.214`.

### Step 3 - Log into the VM

Log into the running VM using the kickstart created `packer` user login as follows.

```shell
$ ssh ${BUILD_USERNAME}@172.31.26.214
osbuild@172.31.26.218's password: 
Register this system with Red Hat Insights: insights-client --register
Create an account or view all your systems at https://red.ht/insights-dashboard
[osbuild@localhost ~]$ 

```

### Step 4 - Reproduce the issue

Once logged into the VM, reproduce the issue by rerunning the problem command:
```shell
[osbuild@localhost ~]$ cd /var/tmp/packer-provisioner-ansible-local
[osbuild@localhost ~]$ export PATH=$PATH:~/.venv/ansible/bin
[osbuild@localhost ~]$ ansible-playbook bootstrap_vm_template.yml --tag vm-template --vault-password-file=~/.vault_pass -e @./vars/vault.yml -c local -i xenv_infra_hosts.yml  
[DEPRECATION WARNING]: Ansible will require Python 3.8 or newer on the controller starting with Ansible 2.12. Current version: 3.6.8 (default, Jan 23 2023, 22:31:05) [GCC 8.5.0 20210514 (Red Hat 8.5.0-18)]. This feature will be removed
 from ansible-core in version 2.12. Deprecation warnings can be disabled by setting deprecation_warnings=False in ansible.cfg.
ERROR! the role 'dcc_common.util.apply_common_groups' was not found in /var/tmp/packer-provisioner-ansible-local/roles:/var/tmp/packer-provisioner-ansible-local/roles:/var/tmp/packer-provisioner-ansible-local

The error appears to be in '/var/tmp/packer-provisioner-ansible-local/bootstrap_vm_template.yml': line 8, column 7, but may
be elsewhere in the file depending on the exact syntax problem.

The offending line appears to be:

  roles:
    - role: dcc_common.util.apply_common_groups
      ^ here
[osbuild@localhost packer-provisioner-ansible-local]$

```

We confirm the same results.

### Step 5 - Fix the playbook and re-run the command

Make necessary corrections on the VM in the ansible staging directory to the playbook as necessary, and re-run until the playbook succeeds.
In this case, we want to replace the reference to the invalid/obsolete `example_old.util` collection to use the correct/current `example.utils` collection.

```shell
[osbuild@localhost ~]$ vi bootstrap_vm_template.yml ## replace  `example_old.util` collection to use the correct/current `example.utils` collection
## now re-run
[osbuild@localhost ~]$ ansible-playbook bootstrap_vm_template.yml --tag vm-template --vault-password-file=~/.vault_pass -e @./vars/vault.yml -c local -i xenv_infra_hosts.yml  

```

Now reproduce the issue by running the problem command:
```shell
[osbuild@localhost ~]$ cd /var/tmp/packer-provisioner-ansible-local
[osbuild@localhost ~]$ ansible-galaxy collection install \
  -r /var/tmp/packer-provisioner-ansible-local/requirements.packer.yml \
  -p /var/tmp/packer-provisioner-ansible-local/galaxy_collections
[DEPRECATION WARNING]: Ansible will require Python 3.8 or newer on the controller starting with Ansible 2.12. Current version: 3.6.8 (default, Jan 23 2023, 22:31:05) [GCC 8.5.0 20210514 (Red Hat 8.5.0-18)]. This feature will be removed
 from ansible-core in version 2.12. Deprecation warnings can be disabled by setting deprecation_warnings=False in ansible.cfg.
Starting galaxy collection install process
Process install dependency map
  
```

At this point we see that ansible.

