# PS Terraform Tool

The PS Terraform Tool enables provisioning Redis Enterprise clusters across multiple cloud vendors using terraform and [terraformpy](https://github.com/NerdWalletOSS/terraformpy)

Currently GCP and AWS are supported, with Azure coming soon

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
 
## Configuration file

The configuration is in yaml format and is by default expected in a file called config.yaml.  A different configuration file can be specified by specifying the path in an environment variable called config.

### Sections

There are currently three sections supported in the configuration: clusters, nameservers, networks

#### nameservers

An optional section that defines the dns configuration for the clusters

##### parent_zone

The name of the zone definition in the cloud provider DNS configuration.   
  
Use aws.ps-redislabs.com for AWS  
Use ps-redislabs for GCP  

##### provider (Optional)

The provider to install the DNS records to.  This is not neccessarily the provider where the cluster was created but the provider that is hosting the DNS domain for the cluster. 

##### domain

This value specifies the subdomain where the FQDN of the cluster will be created.  The resulting FQDN is DEPLOYMENT_NAME-CLUSTER_VPC-DOMAIN  

Use aws.ps-redislabs.com for AWS  
  
Use ps-redislabs.com for GCP

#### networks

Defines VPCs and other characteristics of the network

##### bastion_zone

The zone to which to deploy the vpc's bastion host.  Should match the zones for the selected **provider**  

##### name

The name of the network.  Used to refer to this network while creating a cluster

##### private_cidr

The cidr for the private subnet portion of the vpc.  This is where the Redis Enterprise nodes will be installed.
For AWS, multiple regions and zones require different subnets/CIDRs. Therefore the private_cidr setting is a plain 
string for GCP but a map for AWS where the keys are the zones and the values are the CIDRs.

##### provider

The cloud provider to deploy this vpc to.  One of aws or gcp

##### public_cidr

The cidr for the public subnet portion of the vpc.  This is where the bastion host for the vpc and other services will be installed

##### rack_aware (GCP Only)

Set to **True** if the clusters deployed to this vpc should be rack-aware.  The zones supplied for cluster will be used as the rack_id

*This feature probably makes more sense under the **clusters** section as it is clusters that are rack-aware, not networks*

##### region

The region to deploy the vpc to.  Should match the regions for the selected **provider**

##### vpc_cidr (AWS Only)

The cidr for the VPC

##### bastion_zone

The zone where the bastion node shold be deployed

##### bastion_machine_image

The bastion_machine_image instructs automation which OS image is desired for the bastion node

##### bastion_machine_type

bastion_machine_type specifies which machine type is requested for the bastion node

##### redis_distro

redis_distro contains the URL for the Redis distribution (tar ball) that should be deployed on the cluster nodes

##### peer_with

Only required for AWS if more than one region is used. The value is a ist of network names to which
peering should be requested

#resource_group

The resource_group applies to Azure only! The infrastructure will be deployed in the specified
resource group. The resource group is expected to exist and will neither be created nor deleted.
The service principal needs to have adequate privileges (e.g. contributor) to build infrastructure
in the specified resource group

#### subscription_id

The subscription_id applies to Azure only! It specifies the subscription which should be used 
to create/deploy the infrastructure. The service principal must have sufficient rights
(e.g. contributor) within the subscription

#### tenant_id

The tenant_id applies to Azure only! it lists the Tenant ID, which describes the Active
Directory hosting the service principal

#### application_id

The application_id applies to Azure only! The Application ID is part of the service principal
identification

#### client_certificate_path: /Users/audi/Documents/GIT/rl-terraform/terraform_account.pfx
The client_certificate_path applies to Azure only! It points to a file (PFX format) containing
the credentials of the service principal

#### clusters

Defines the clusters to be deployed

##### expose_ui

Exposes the Redis Enterprise UI.  This is currently IP based, hence not secure.  The IP will be provided in the output once terraform runs

##### machine_type

The machine instance type to deploy on.  Should match the instance types supplied by selected *provider*

##### vpc

The vpc to deploy which to deploy the cluster.  A reference to *network.name*

##### worker_count

The number of machines to deploy, one of which will be a main node

##### zones

An array of zones to which to deploy the Redis Enterprise nodes.  The zones are applied to the workers in a round robin fashion.  If there are more zones than workers, the extraneous zones are ignored.  If there are more workers than zones, the list is restarted.  Should match the zones for the selected **provider**  

#### machine_image

OS image desired to deploy on the cluster nodes

### Example

```
clusters:
  - vpc: vpc-central
    worker_count: 3 
    machine_type: n1-standard-4
    zones: 
    - us-central1-a
    - us-central1-b
    - us-central1-c
    expose_ui: True
  - vpc: vpc-east
    worker_count: 3 
    machine_type: t2.xlarge 
    zones: 
    - us-east-1c
    - us-east-1c
    - us-east-1c
    expose_ui: False
networks:
  - name: vpc-central
    public_cidr: 10.1.0.0/24
    private_cidr: 10.2.0.0/16 
    region: us-central1
    bastion_zone: us-central1-f
    rack_aware: True
    provider: gcp
  - name: vpc-east
    vpc_cidr: 10.0.0.0/16
    public_cidr: 10.0.1.0/24
    private_cidr: 10.0.2.0/24
    region: us-east-1 
    bastion_zone: us-east-1c
    provider: aws
    zone: us-east-1c
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

- Active/Active between zones/cloud providers
- Other services like grafana/ldap etc
