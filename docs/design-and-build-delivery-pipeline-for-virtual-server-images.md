
# Design and Build a Delivery Pipeline for Virtual Server Images

## How to design a continuous integration and continuous deployment (CI/CD) for virtual machines in VMware Vsphere Datacenter.

Software is crucial for business — even established businesses. The front door is an application running on a phone or a website. Sales and marketing rely on customer relationship management (CRM) systems. Shipping and receiving are automated logistics.

Delivering new versions of software is the cornerstone of continuous improvement. Continuous integration and continuous deployment (CI/CD) is a proven strategy for delivering high-quality software. At its core, CI/CD captures the steps to create and deploy software. The goal is to remove humans from the mundane by automating the steps to improve reliability and deliver fixes and features more frequently.

This article will cover the issues around the automated development of software for virtual server instances (VSIs). There is a companion [GitHub](https://github.com/lj020326/packer-templates) repository that demonstrates a few of these concepts.  

The VM template build jobs are enabled using a jenkins shared library to automate the VM template build found at the [github repo here](https://github.com/lj020326/pipeline-automation-lib).  The same library defines the `INFRA` project pipelines, including the vm-templates jobs with [job-dsl definition here](https://github.com/lj020326/pipeline-automation-lib/blob/main/jobs/jobdsl/templates/01_INFRA/init02_vm_templates.groovy).

The jenkins environment is setup using jenkins configuration-as-code.  Ansible creates a docker swarm setup and leverage a template to render the jenkins runtime configuration at `jenkins_home/casc/jenkins.yml`.  The ansible template used can be found in the [ansible repo on github here](https://github.com/lj020326/ansible-datacenter/blob/main/roles/bootstrap_docker_stack/templates/jenkins_jcac/jenkins_casc.yml.j2).

The `seedjob.groovy` found at bottom of the `jenkins_home/casc/jenkins.yml` configuration is used upon starting jenkins to define/render/bootstrap all of the project folders and jobs/pipelines used within each project in code using jenkins job-dsl.   The seedjob executes all of the `*.groovy` files located in the pipeline repo's `jobs/jobdsl/template/` folders.  This allows a systematic method to create project+pipeline specific groovy files that can be used to completely bootstrap all projects.  

## Background

[VMware Vsphere Datacenter](https://www.ibm.com/cloud/virtual-servers) provides compute instances with various flavors of CPU, memory, network and storage options for securely running workloads. Virtual server instance (VSI) images are the initial contents of the boot disk of a VPC instance.

IBM has documented a number of off-the-shelf [architectures](https://www.ibm.com/cloud/architecture) in the architecture center — like [workloads in IBM VPC](https://www.ibm.com/cloud/architecture/architectures/deploy-workloads-on-virtual-servers-icp). Part of implementing the architecture is delivering software to the virtual server instances. Focusing the architecture lens on a single instance looks like this:

![Part of implementing the architecture is delivering software to the virtual server instances. Focusing the architecture lens on a single instance looks like this:](https://www.ibm.com/blog//wp-content/uploads/2022/09/db1.png)

-   The app is an image running on a VSI.
-   1.1 is the version of the app.

It’s reasonable to bake the application into a VSI image. Each application release will create a new version of the image, and the image will pass through a number of phases: build stage, test stage, pre-production stage and the final deployment to production. VSIs in a stage are provisioned with the new image version to deploy the software.

## Create a pipeline to create and deploy VSI images

Automated pipelines are can be integrated into automated tools like [DevOps toolchains](https://www.ibm.com/cloud/architecture/toolchains/). The automated steps will start with an IBM stock image and create custom images as the software is developed and fixes are applied. The custom images are then deployed into the staging environment.

### Basic pipeline

![Basic pipeline](https://www.ibm.com/blog//wp-content/uploads/2022/09/db2.png)

-   The stock images are provided by IBM and regularly updated.
-   The dept images are images created by the department. The image to deploy to stage is tagged with **stage**. Notice how that tag was “moved” from dept-1-1 to dept-1-2.

Steps:

-   Image pipeline:
    -   Start with an IBM stock image.
    -   Create a new image with desired changes.
    -   Delete the stage tag from the previous version.
    -   Add the version tag and stage tag to the new image.
-   Stage pipeline:
    -   Notice that a new image with the stage tag is available.
    -   Provision the architecture with the new image.

### Multi-stage pipeline

An organization can have a central set of images that serve as the base images for all development departments:

![An organization can have a central set of images that serve as the base images for all development departments:](https://www.ibm.com/blog//wp-content/uploads/2022/09/db3.png)

Corporate images are base images used by all departments.

## Create an image pipeline with Packer

[Packer](https://www.packer.io/) with the [IBM plugin](https://github.com/IBM/packer-plugin-ibmcloud) can be used to create images. The article “[Build Hardened and Pre-Configured VPC Custom Images with Packer](https://www.ibm.com/cloud/blog/build-hardened-and-pre-configured-vpc-custom-images-with-packer)” provides an introduction. Here are some snippets of the Packer configuration that define a starting point using an IBM stock image. Provisioners are used to install software like nginx or your application. More steps are needed to further configure the application runtime environment, but you get the idea. Below is a cut-down of this [full example](https://github.com/IBM-Cloud/vsi-ci-cd/blob/main/ubuntu-hello.pkr.hcl):

```
packer {
  required_plugins {
    ibmcloud = {
      source  = "github.com/IBM/ibmcloud"
    }
  }
}

source "ibmcloud-vpc" "ubuntu" {
  vsi_base_image_name = "ibm-ubuntu-22-04-minimal-amd64-1"
}

provisioner "shell" {
  inline = [
    "apt -qq -y install nginx < /dev/null",
  ]
}

provisioner "file" {
  source = "app.tar.gz"
  destination = "/root/app.tar.gz"
}
```

Basic steps that are triggered by a change in the application:

-   Create an image using Packer.
-   Signal the next stage — the deploy pipeline.

## Create a deploy pipeline to deploy the new image

The deploy pipeline in the diagram above is for provisioning new VSIs to run images generated by the image pipeline.

Steps:

-   Create a VPC Subnet and other resources.
-   Wait for signal from previous stage.
-   Provision new VSIs running new image.

The VPC architecture and corresponding VSIs will depend on the problem being solved. They could be as simple as a single VSI or more complicated like the [three-tier architecture](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-create-three-tier-architecture). The provision/destroy steps will depend on the architecture. It may be sufficient to invoke a Terraform script that uses the dynamic evaluation of tags to identify the image (see example [vpc.tf](https://github.com/IBM-Cloud/vsi-ci-cd/blob/main/simple_tf/vpc.tf)). Alternatively, you can use the [IBM Cloud Command Line Interface](https://www.ibm.com/cloud/cli) to find the image with the stage tag:

```
ibmcloud resource search 'service_name:is AND type:image AND tags:"stage"'
```

You will need to consider a replacement strategy for the existing VSIs. Other resources may be dependent on an existing VSI. For example, load balancers or DNS entries are dependent on the private IP addresses of the VSI. Here are some possible scenarios:

### Preserve the VSI IPs

The [reserved IPs](https://cloud.ibm.com/docs/vpc?topic=vpc-managing-ip-addresses&interface=ui) capability of VPC allows you to reserve an IP address in a subnet. The destroy followed by a provision of a VSI will result in the same IP address. Here is an example Terraform snippet:

```
resource "ibm_is_subnet" "zone" { }
resource "ibm_is_subnet_reserved_ip" "instance" {
  subnet = ibm_is_subnet.zone.id
}
resource "ibm_is_instance" "test" {
  image          = data.ibm_is_image.name.id  // new image version to provision
  primary_network_interface {
    subnet = ibm_is_subnet.zone.id
    primary_ip {
      reserved_ip = ibm_is_subnet_reserved_ip.instance.reserved_ip
    }
  }
}
```

### DNS record or load balancer update

It may be advantageous to provision the new VSI application using a new IP address. After both are running, you can change the dependent resources. Update the DNS record to the new IP address when both the old and new VSIs are active. Load balancer pool members can be handled similarly.

### VPC instance group

Instance groups allow [bulk provisioning](https://cloud.ibm.com/docs/vpc?topic=vpc-bulk-provisioning). An instance group can even be the pool for a [load balancer](https://cloud.ibm.com/docs/vpc?topic=vpc-lbaas-integration-with-instance-groups). The image is specified by an [instance template](https://cloud.ibm.com/docs/vpc?topic=vpc-managing-instance-template) resource. Create a new instance template for the new image version and connect it to the instance group. New instances will be provisioned using the new image. You will need to remove the instances running the previous image version.

The diagrams below show the _before_ on the left, and the _after_ on the right:

![The diagrams below show the before on the left, and the after on the right:](https://www.ibm.com/blog//wp-content/uploads/2022/09/db4.png)

-   Create a new Instance Template with version 1.2 of the image.
-   Initialize the Instance Group with the new Instance Template.
-   Delete the Instance Group Members running the previous versions.

## Summary and next steps

Automating software build, test, integration and deploy will improve software quality. Virtual machine images can be the foundation of the process. [VMware Vsphere Datacenter](https://www.ibm.com/cloud/virtual-servers) has the compute capacity along with the isolation and control to make it simple, powerful and secure.

More reading:

-   [Scale workloads in shared and dedicated VPC environments](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-scaling-dedicated-compute)
-   [Build Hardened and Pre-Configured VPC Custom Images with Packer](https://www.ibm.com/cloud/blog/build-hardened-and-pre-configured-vpc-custom-images-with-packer)
-   [Deploy isolated workloads across multiple locations and zones](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-multi-region)
-   [Install software on virtual server instances in VPC](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-app-deploy)
-   [Getting started with Terraform on IBM Cloud](https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-getting-started)
-   [Getting started with Continuous Delivery](https://cloud.ibm.com/docs/ContinuousDelivery?topic=ContinuousDelivery-getting-started)
-   [IBM Packer Plugin](https://github.com/IBM/packer-plugin-ibmcloud)
-   [Getting started with Terraform on IBM Cloud](https://cloud.ibm.com/docs/ibm-cloud-provider-for-terraform?topic=ibm-cloud-provider-for-terraform-getting-started)

If you have feedback, suggestions or questions about this post, please [email me](mailto:pquiring@us.ibm.com) or reach out to me on Twitter ([@powellquiring](https://twitter.com/powellquiring)).