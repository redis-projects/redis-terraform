# PS Terraform Tool

The PS Terraform Tool enables provisioning Redis Enterprise clusters across multiple cloud vendors using terraform and [terraformpy](https://github.com/NerdWalletOSS/terraformpy)

Currently GCP and AWS and Azure are supported

The terraform state file is currently maintained locally.  This means:
- Only one deployment is supported for each directory where the script is executed (terraform state file)
- Deployments created by other individuals will not be updatable


## Prerequisites

- Install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Install [Python 3.7 and above](https://www.python.org/downloads/)
- Install [virtualenv](https://virtualenv.pypa.io/en/latest/installation.html) *(Optional)*
- SSH key file

GCP setup:
- Download a [GCP service account key file](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)
- Save the file as terraform_account.json

AWS setup
- Download a [AWS service account key file](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
- export AWS_ACCESS_KEY_ID=*first entry in file*
- export AWS_SECRET_ACCESS_KEY=*second entry in file*
- export AWS_DEFAULT_REGION=*region*.  This should be the same region the bastion and nodes will be deployed to.

Azure setup
The etup is slightly different. First of all, you must have an existing 
"Resource Group" in Azure that you will attach the infrastructure to. 
Then you need to create a service principal which has at least the role
"Contributor" in that resource group. We recommend using a service 
principal with a certificate but a password also supported
- create a resource group Azure
- create a service principal in Azure who has a "contributor" role 
  for the above resource group
- store the certificate file as e.g. terraform_account.pfx. In cae you 
  use a password, store user (=application id) and password in the
  environment variables AZURE_ACCESS_KEY_ID and AZURE_SECRET_ACCESS_KEY 
 
## Configuration file

The configuration is in yaml format and is by default expected in a file called config.yaml.  A different configuration file can be specified by specifying the path in an environment variable called config.

Options for the rl-terraform configuration file
===============================================
"clusters" Section
------------------

This section of the yaml file describes how the Redis clusters should look like, e.g. their size and types where they should be deployed.

1.  **expose_ui** *[optional]*\
    Access to the Redis cluster through the GUI (running on port 843/tcp) is very cumbersome because the cluster nodes are accessible to the "outside world". One way to solve this problem is to use X11 forwarding when connecting to the bastion node and opening a browser window there, connecting to the cluster nodes. A simpler way to solve the problem is when you set the value of "expose_ui" to "True". This will create a network load balancer in your VPC with a public or private IP address that is distributing traffic on port 8443 in a round-robin fashion to the Redis cluster nodes. In that case, you can simply point your browser to the frontend IP address on port 8443 and connect to the cluster directly. For security reasons, we would not recommend public IPs for any production environments.\
    Example:

    ```
    expose_ui: True
    ```

2.  **machine_image** *[required]*\
    This key determines the OS image for the Redis cluster nodes (all nodes use the same image). The image is of course highly dependent on the cloud provider and in addition, you need to ensure the image is available in your desired region. For AWS, the same image often has a different name in different regions. For GCP and Azure, you cannot assume that the same image exists in all regions. You must make sure the image you specify is available in the region you specify.\
    Examples:

    ```
    (AWS) machine_image: ami-05f238ddab9a512be
    (GCP) machine_image: rhel-8-v20210721
    (Azure) machine_image: OpenLogic:CentOS:7.5:7.5.201808150
    ```

3.  **machine_type** *[required]*\
    machine_type specifies the type of hardware (VM type) to be selected for the Redis cluster nodes. This type is provider-specific and determines parameters like number of CPUs, size f the memory, size of the disks, etc. You must ensure that your machine_type is available in the region you select and that you have quota and permissions to create these VM instances.\
    Examples:

    ```
    (AWS) machine_type: t2.xlarge
    (GCP) machine_type: n1-standard-4
    (Azure) machine_type: Standard_B2s
    ```

4.  **name** *[required]*\
    Each cluster must have a **unique** name attached to it\
    Example

    ```
    name: az-redis-cluster
    ```

5.  **rack_aware** *[required]*\
    This key is boolean (True or False) and lets you choose if the cluster to be built should take the availability zones into account for a better resiliency (e.g. one availability zone going down)\
    Example:

    ```
    rack_aware: True
    ```

6.  **redis_distro** *[required]*\
    This field is required and points to the URI to download the Redis Enterprise software from\
    Example:

    ```
    redis_distro: https://s3.amazonaws.com/redis-enterprise-software-downloads/6.2.8/redislabs-6.2.8-53-rhel7-x86_64.tar
    ```

7.  **worker_count** *[required]*\
    Its value is of type integer and specifies the number of Redis cluster nodes.\
    Example:

    ```
    worker_count: 3
    ```

8.  **vpc** *[required]*\
    The value of vpc is the name of the VPC (Virtual Private Cloud) where the RE cluster will be deployed. This VPC must be defined with the identical name in the "Networks" section of the config file.\
    Examples:

    ```
    vpc: vpc-aws-europe
    vpc: vpc-gcp
    vpc: vnet-azure
    ```

9.  **zones** *[required]*\
    "zones" is of a type list/array and specifies which availability zones are to be used for the Redis cluster nodes. Often, the number of zones equals the number of cluster nodes but you can have more cluster nodes than zones. In that case, the zones are used in a round-robin fashion. If, for example, you had 3 zones and 7 nodes two zones would host 2 nodes and one zone would host 3 nodes.\
    Examples:

    ```
    zones:
      - eu-central-1c
      - eu-central-1b
      - eu-central-1a
      
    zones:
      - europe-west3-a
      - europe-west3-b
      - europe-west3-c
      
    zones:
      - 1
      - 2
      - 3
    ```

"global" Section
----------------

Currently, this section is optional. It supports only the keyword "resource_tags"

1.  **resource_tags** *[optional]*\
    resource_tags has a map/hash/dictionary as its value. This value defines all key-value pairs that will be added as 'tags' for Azure und AWS for the resources. This makes it easy to search for specific resources deployed by the "terraform" run. This feature exists only to provide a better description/tagging of the resources

"nameservers" Section
---------------------

This section is not required but optional. Adding this section to your config file only makes sense when your parent DNS zone is hosted in AWS or GCP. As an example: If your clusters would be "cluster1.myredisclusters.mycompany.com" the parent zone is "myredisclusters.mycompany.com". This DNS parent zone needs to be hosted in AWS (Route53) or GCP (Cloud DNS) and you need permissions to make modifications to that parent zone. In that case, the necessary NS-records and A-records will be added automatically through terraform and you don't need to make any DNS adjustments manually. But if you don't have permission to modify the parent zone or if you use your own company-DNS infrastructure, don't specify this section.

1.  **cluster** *[required]*\
    This property refers to the cluster in the "clusters" section and must match one value of the "name" property of the "clusters" section. The DNS entries will be created for this cluster.\
    Example:

    ```
    cluster: aws-redis-cluster
    ```

2.  **domain** *[required]*\
    The domain value sets the DNS subdomain in which the cluster gets created. The resulting FQDN of the cluster will be <CLUSTER>.<DOMAIN>\
    Example:

    ```
    domain: aws.ps-redislabs.com
    ```

3.  **parent_zone** *[required]*\
    This key specifies the name of the DNS zone used in your provider DNS configuration. Often, this name is identical to the domain variable. But it can also be different.\
    Example:

    ```
    parent_zone: aws.ps-redislabs.com
    ```

4.  **provider** *[optional]*\
    As a default setting, we assume that the provider of the cluster VMs is also the provider hosting DNS and in that case, the key "provider" doesn't need to be specified. In case you for example provision a cluster in AWS but the DNS zone is hosted in GCP you need to set the provider for the DNS hosting.\
    Examples:

    ```
    provider: aws
    provider: gcp
    provider: azure
    ```

5.  **vpc** *[required]*\
    The value of vpc is the name of the vpc (Virtual Private Cloud) which is used as the Terraform "provider" creating the DNS records\
    Examples:

    ```
    vpc: vpc-aws-europe 2vpc: vpc-gcp 3vpc: vnet-azure-asia
    ```

"networks" Section
------------------

1.  **application_id** *[required]*\
    The "application_id" parameter is only meaningful and required for Azure deployments. It specifies the user or application ID of your service principal. It can be retrieved from the Azure portal.\
    Examples:

    ```
    subscription_id: ef44f35d-d2ad-9491-b1a4-3aff1c2143f9
    ```

2.  **bastion_machine_image** *[required]*\
    This key is used to set the OS image for the bastion node. As for the cluster nodes, you must make sure that the image is available in the desired zone.\
    Example:

    ```
    bastion_machine_image: ami-0b1db37f0fa006678
    bastion_machine_image: OpenLogic:CentOS:7.5:7.5.201808150
    bastion_machine_image: rhel-7-v20210721
    ```

3.  **bastion_machine_type** *[required]*\
    This value sets the hardware type of the bastion node. Bastion nodes are typically much smaller than the Redis cluster nodes as they handle only interactive sessions. Ensure the availability of the specified hardware type in the desired region.\
    Examples:

    ```
    bastion_machine_type: t2.micro
    bastion_machine_type: n1-standard-1
    bastion_machine_type: Standard_B2s
    ```

4.  **bastion_zone** *[required]*\
    "bastion_zone" advises Terraform which availability zone should be used to place the bastion node. The zone must of course be valid for your provider.\
    Examples:

    ```
    bastion_zone: europe-west3-b 2bastion_zone: us-east-1c 3bastion_zone: 3
    ```

5.  **client_certificate_path** *[optional]*\
    The "client_certificate_path" parameter is only meaningful and required for Azure deployments. It specifies the file where the certificate of the service principal is stored.\
    Examples:

    ```
    client_certificate_path: /home/homer/secrets/mycert.pfx
    ```

6.  **client_secret** *[optional]*\
    The "client_secret" parameter is only meaningful and required for Azure deployments. It specifies the password of the service principal in clear text\
    Examples:

    ```
    client_certificate_path: /home/homer/secrets/mycert.pfx
    ```

7.  **lb_cidr** *[required]*\
    This flag is required for AWS. Public DNS resolvers will need access to the DNS processes running on the Redis cluster nodes in the private subnet. To fulfill this requirement a network load balancer for DNS attaches all Redis cluster nodes as its backend. The frontend (listener) for port 53/udp must be reachable from the internet, therefore a subnet is created using an internet gateway where the frontend of the DNS load balancer is living. This subnet is specified with lb_cidr. For AWS, one subnet cannot span across multiple availability zones. For resiliency, we need to have load balancers in all zones and we must therefore specify a map/hash/dictionary of availability zones and CIDRs.\
    Example:

    ```
    lb_cidr:
      ap-south-1a: 10.99.0.0/28
      ap-south-1b: 10.99.0.16/28
      ap-south-1c: 10.99.0.32/28
    ```

8.  **name** *[required]*\
    The "name" key specifies the name of the VPC (Virtual Private Cloud) to be created. This value is referenced in the other sections ("clusters" and "networks") through their "vpc" key.\
    Examples:

    ```
    name: vpc-aws-us
    name: vpc-gcp
    name: vnet-azure
    ```

9.  **peer_with** *[optional]*\
    This tool was designed to provide not only single clusters but also multiple Redis Enterprise clusters in an A-A (active-active) configuration. This of course requires that clusters in different VPCs can communicate with each other. This is currently supported through "VPC peering" within a single provider and VPN tunnels across different providers. Therefore we implement VPC peering between clusters from the same cloud provider. By default, no peering is set up unless you specify the "peer_with" key. Its value is a **list/array** of VPCs you would like to peer with. You only need to specify the VPC peering requestor in the config file, the acceptor is automatically derived.\
    Example:

    ```
    peer_with:
      - vpc-aws-europe
    ```

10. **private_cidr** *[required]*\
    GCP and Azure provide the luxury of subnets that can span across multiple availability zones. For AWS, that is not the case. Therefore, the type of the private_cidr is different between AWS and GCP/Azure. For GCP/Azure it is just one value, the CIDR of the private subnet containing all Redis cluster nodes. For AWS deployments, the value is a hash/directory of CIDRs specifying the private subnets for each availability zone.\
    Examples:

    ```
    #AWS eample
    private_cidr:
      us-east-1a: 10.1.3.0/24
      us-east-1b: 10.1.2.0/24
      us-east-1c: 10.1.4.0/24
      
    #GCP example
    private_cidr: 10.2.0.0/16
    
    #Azure example
    private_cidr: 10.71.0.128/25
    ```

11. **project** *[required]*\
    This key is only relevant for GCP. The value of "project" is the name of the GCP project to be used for the deployment.\
    Example:

    ```
    project: redislabs-sa-training-services
    ```

12. **provider** *[required]*\
    This value sets the cloud provider (currently "aws", "azure" and "gcp") for the VPC and cluster deployment.\
    Example

    ```
    provider: aws
    provider: gcp
    provider: azure
    ```

13. **public_cidr** *[required]*\
    public_cidr specifies the subnet which is used for the bastion node. This public subnet is open to the "outside world". It must be a subnet of the vpc_cidr for AWS deployments. As described for the "private_cidr" the same rules apply to the "public_cidr". For GCP and Azure, one public subnet is required because it can span availability zones. For AWS, one subnet per availability zone is required; therefore public_cidr is a hash/map/dictionary for AWS\
    Example:

    ```
    #AWS eample
    public_cidr:
      us-east-1a: 10.3.3.0/16
      us-east-1b: 10.3.2.0/16
      us-east-1c: 10.3.4.0/16

    #GCP example
    public_cidr: 10.3.0.0/16

    #Azure example
    public_cidr: 10.3.0.0/16
    ```

    For this example, all addresses in the public subnets start with 10.3.X.Y

14. **region** *[required]*\
    The "region" parameter tells terraform where the VPC should be deployed. Its value depends on the cloud provider, you must make sure that you specify a valid region for your provider.\
    Examples:

    ```
    region: us-east-1
    region: europe-west3
    region: CentralIndia
    ```

15. **resource_group** *[required]*\
    The "resource_group" parameter is only meaningful and required for Azure deployments. Take into account that the specified resource group must already exist when you start the terraform deployment.\
    Examples:

    ```
    resource_group: az-test-rg
    ```

16. **resource_name** *[optional]*\
    The "resource_name" parameter overwrites the default name for the VPC or VNET with your specified value\
    Examples:

    ```
    resource_name: az-redis-vnet
    ```

17. **subscription_id** *[required]*\
    The "subscription_id" parameter is only meaningful and required for Azure deployments. This parameter identifies the ID of your Azure subscription. It can be retrieved from the Azure portal.\
    Examples:

    ```
    subscription_id: ef35f66d-d2ad-4991-b1a4-3aff1c5734f8
    ```

18. **tenant_id** *[required]*\
    The "tenant_id" parameter is only meaningful and required for Azure deployments. It specifies the ID or your AD (Active Directory). It can be retrieved from the Azure portal.\
    Examples:

    ```
    subscription_id: ef44f35d-d2ad-9491-b1a4-3aff1c2143f9
    ```

19. **ui_cidr** *[optional]*\
    If this flag is not set and the "expose_ui" flag is set to "True" the load balancer with the Redis cluster nodes port 8443/tcp at its backend will have a public IP address for the frontend. This is convenient when setting up a demo cluster but of course a big security risk for anything productive secret. In those cases, you might want to have the frontend of the UI load balancer point to in internal/private network. You can control who would have access to this load balancer frontend. For Azure and GCP, the backend nodes (Redis cluster nodes) are all in one subnet. For AWS, one subnet per availability zone is required. Therefore, the same rules tat apply to the public and private subnet specifications. A single value for GCP/Azure, a map/hash/dictionary for AWS. If 'expose_ui' is set to 'False' ui_cidr meaningless\
    Examples:

    ```
    #AWS eample
    ui_cidr:
      ap-south-1a: 10.100.1.0/28
      ap-south-1b: 10.100.1.16/28
      ap-south-1c: 10.100.1.32/28

    #GCP example
    ui_cidr: 10.100.5.0/24

    #Azure example 
    ui_cidr: 10.100.64.0/24
    ```

20. **vpc_cidr** *[required]*\
    The vpc_cidr specification applies **only** to AWS and Azure deployments. It is meaningless for GCP deployments. All subnets (public and private) need to be subnets of the vpc_cidr.\
    Example:

    ```
    vpc_cidr: 10.1.0.0/16
    ```

    In the above example, all subnets need to have the addresses 10.1.X.Y

"servicenodes" Section
----------------------

Service nodes, as the name implies are provisioned to run all sorts of services. If only a few resources are required, service nodes are not needed but small services could be started on the bastion node. But for better isolation and providing more resources, one can request one or multiple service nodes to be deployed. These nodes will be placed on the public subnet and they will be getting public IP addresses. The services which will be running on these nodes are specified in the 'services' section of this configuration file. It could be services like grafana, prometheus, RIOT etc.

1.  **count** *[required]*\
    The "count" parameter determines the number of nodes to be deployed in this group of service nodes\
    Examples:

    ```
    count: 3
    ```

2.  **vpc** *[required]*\
    The value of vpc is the name of the VPC (Virtual Private Cloud) where the service nodes will be deployed. This VPC must be defined with the identical name in the "Networks" section of the config file.\
    Examples:

    ```
    vpc: vpc-aws-europe
    vpc: vpc-gcp
    vpc: vnet-azure
    ```

3.  **machine_image** *[required]*\
    This key determines the OS image for the service nodes (all nodes use the same image). The image is of course highly dependent on the cloud provider and in addition, you need to ensure the image is available in your desired region. For AWS, the same image often has a different name in different regions. For GCP and Azure, you cannot assume that the same image exists in all regions. You must make sure the image you specify is available in the region you specify.\
    Examples:

    ```
    (AWS) machine_image: ami-05f238ddab9a512be
    (GCP) machine_image: rhel-8-v20210721
    (Azure) machine_image: OpenLogic:CentOS:7.5:7.5.201808150
    ```

4.  **machine_type** *[required]*\
    machine_type specifies the type of hardware (VM type) to be selected for the service nodes. This type is provider-specific and determines parameters like number of CPUs, size f the memory, size of the disks, etc. You must ensure that your machine_type is available in the region you select and that you have quota and permissions to create these VM instances.\
    Examples:

    ```
    (AWS) machine_type: t2.xlarge
    (GCP) machine_type: n1-standard-4
    (Azure) machine_type: Standard_B2s
    ```

5.  **zones** *[required]*\
    "zones" is of a type list/array and specifies which availability zones are to be used for the service nodes. Often, the number of zones equals the number of cluster nodes but you can have more cluster nodes than zones. In that case, the zones are used in a round-robin fashion. If, for example, you had 3 zones and 7 nodes two zones would host 2 nodes and one zone would host 3 nodes.\
    Examples:

    ```
    zones:
    - eu-central-1c 
    - eu-central-1b
    - eu-central-1a
    
    zones:
    - europe-west3-a
    - europe-west3-b
    - europe-west3-c
    
    zones: 
    - 1
    - 2
    - 3
    ```

6.  **name** *[required]*\
    Each group of service nodes must have a **unique** name attached to it. This property is referenced in the "services" section of the configuration file\
    Examples:

    ```
    name: prod-service-nodes-az
    name: prod-service-nodes-aws
    name: prod-service-nodes-gcp
    ```

"services" Section
------------------

1.  **contents** *[required]*\
    There are pre-defined services to run, as of now there is "vi". This service provides Grafana, prometheus and RIOT\
    Examples:

    ```
    contents: vi
    ```

2.  **name** *[required]*\
    Each service must have a **unique** name attached to it.\
    Examples:

    ```
    name: vi-aws
    name: vi-az
    name: vi-gcp
    ```

3.  **servicenode** *[required]*\
    Each service must have a **unique** name attached to it.\
    Examples:

    ```
    name: prod-service-nodes-aws 
    name: prod-service-nodes-az
    name: prod-service-nodes-gcp
    ```

4.  **type** *[required]*\
    The current implementation supports only one type which is "docker".\
    Examples:

    ```
    type: docker
    ```

### Example

```
---
global:
  resource_tags:
    owner: Homer Simpson
    env: production
    service: donut
clusters:
  - name: az-redis-cluster
    vpc: prod-az-redis
    worker_count: 3
    machine_type: Standard_B2s
    machine_image: OpenLogic:CentOS:7.5:7.5.201808150
    zones:
    - 1
    - 2
    - 3
    expose_ui: True
    redis_distro: https://s3.amazonaws.com/redis-enterprise-software-downloads/6.2.8/redislabs-6.2.8-53-rhel7-x86_64.tar
    rack_aware: True
  - name: aws-redis-cluster
    vpc: prod-aws-redis
    worker_count: 3
    machine_type: t3.medium
    machine_image: ami-04c84f136b3c9d872
    zones:
    - ap-south-1a
    - ap-south-1b
    - ap-south-1c
    expose_ui: True
    redis_distro: https://s3.amazonaws.com/redis-enterprise-software-downloads/6.2.8/redislabs-6.2.8-53-rhel7-x86_64.tar
    rack_aware: True
networks:
  - name: prod-az-redis
    resource_name: az-redis-vnet
    vpc_cidr: 10.71.0.0/22
    public_cidr: 10.71.1.0/25
    private_cidr: 10.71.0.128/25
    lb_cidr: 10.71.2.0/24
    gateway_cidr: 10.71.3.0/26
    region: CentralIndia
    bastion_zone: 3
    bastion_machine_image: OpenLogic:CentOS:7.5:7.5.201808150
    bastion_machine_type: Standard_B2s
    provider: azure
    resource_group: ps-verse-rg
    subscription_id: ef03f41d-d2bd-4691-b3a0-3aff1c6711f7
    tenant_id: 1428732f-21cf-469e-ad48-5721f4eac1e2
    application_id: e333cbb0-7738-470a-8472-d9fe7484b217
    client_certificate_path: /Users/audi/.ssh/ps-verse-keyvault-ps-verse-20220208.pfx
  - name: prod-aws-redis
    resource_name: aws-redis-vpc
    vpc_cidr: 10.17.0.0/23
    public_cidr:
      ap-south-1a: 10.17.0.64/26
      ap-south-1b: 10.17.0.128/26
      ap-south-1c: 10.17.0.192/26
    private_cidr:
      ap-south-1a: 10.17.1.64/26
      ap-south-1b: 10.17.1.128/26
      ap-south-1c: 10.17.1.192/26
    lb_cidr:
      ap-south-1a: 10.17.0.0/28
      ap-south-1b: 10.17.0.16/28
      ap-south-1c: 10.17.0.32/28
    ui_cidr:
      ap-south-1a: 10.17.1.0/28
      ap-south-1b: 10.17.1.16/28
      ap-south-1c: 10.17.1.32/28
    region: ap-south-1
    bastion_zone: ap-south-1c
    bastion_machine_image: ami-04c84f136b3c9d872
    bastion_machine_type: t3.medium
    peer_with:
    - prod-az-redis
    provider: aws
services:
  - type: docker
    name: vi-aws
    contents: vi
    servicenode: prod-service-nodes-aws
  - type: docker
    name: vi-az
    contents: vi
    servicenode: prod-service-nodes-az
servicenodes:
  - name: prod-service-nodes-az
    vpc: prod-az-redis
    count: 1
    machine_type: Standard_B2s
    machine_image: OpenLogic:CentOS:7.5:7.5.201808150
    zones:
    - 1
  - name: prod-service-nodes-aws
    vpc: prod-aws-redis
    count: 1
    machine_type: t3.medium
    machine_image: ami-04c84f136b3c9d872
    zones:
    - ap-south-1a
nameservers:
  - cluster: aws-redis-cluster
    vpc: prod-aws-redis
    parent_zone: aws.ps-redislabs.com
    domain: aws.ps-redislabs.com
    provider: aws
  - cluster: az-redis-cluster
    vpc: prod-aws-redis
    parent_zone: aws.ps-redislabs.com
    domain: aws.ps-redislabs.com
    provider: aws
```

## Running
- Clone this repository
- Configure ssh
   - add the following to your .ssh/config.  *Not sure if this is necessary as I don't have the setting on my ubuntu vm and it worked ok.  May be necessary for other OS*
    ```Host *
     StrictHostKeyChecking no
     ForwardAgent yes
    ```
   - For macs:
     - ssh-agent
     - ssh-add -K ~/.ssh/id_rsa
   - For linux:
     - eval $(ssh-agent)
     - ssh-add
- Install Python dependencies
  - pip install -r requirements.txt
- Execute terraformpy
  - PYTHONPATH=. name=xxxxx config=ccccc terraformpy, where xxxxx is the name to give this deployment and config is an optional parameter to specify a different config file from config.yaml
- Run terraform:
  - terraform init
  - terraform plan
  - terraform apply
- Once done, you should see some output information:
  - *provider*-bastion-*`network.name`*-ip-output: This is the IP for the bastion host for the vpc.  You need this to access the nodes
  - *provider*-re-ui-`*network.name*`-ip-output: This is the IP for the exposed Redis Enterprise UI, if **expose_ui** was selected.  The UI can be accessed at https://*ui-ip*:8443/.  Note that the connection will not be secure.

## Accessing Redis Enterprise Node VMs

The created nodes are in a private subnet so it is necessary to go through the bastion host.  The IP address of the bastion for each vpc is provided in the terraform output

- SSH to the bastion host
  - GCP: ssh -A redislabs@*bastion-ip*
  - AWS: ssh -A ec2-user@*bastion-ip*
- Retrieve the host names or IP
  - cat redis-ansible/inventories/boa-cluster.ini
- SSH to the instances
  - ssh redislabs@*ip*
- Access cluster endpoint
  - From bastion: curl -k --fail -u admin@admin.com:admin https://*ip*:9443/v1/nodes.  You can also use the DNS names provided as terraform output
  - From Redis Enterprise node: curl -k --fail -u admin@admin.com:admin https://localhost:9443/v1/nodes

## Creating cross provider CRDB
When multiple clusters are spanning multiple providers, we create ssh tunnels between the clusters and their respective base_sections
to be able to create a CRDB that makes use of this ssh tunnels, use the crdb-cli command under `templates/aa-rladmin.tpl`. Before that, you need to make sure that all-nodes proxy policy is applied (rladmin commands are provided in the same tpl file). 

## Features Coming soon

- Active/Active between GCP/AWS and GCP/Azure
- More services
