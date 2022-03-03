# Changelog

Tracking all changes for the "Terraform" project building Redis-Enterprise
clusters on a public clould infrastructure.

## [0.9.1] - Released
### Added
- New "docker" service implemented and a vault as POC
- Adding VPN functionality between AWS and Azure
- RIOT is introduced to migrate Redis data as part of the new 'services'
- grafana has been added to the 'services' for monitoring
- prometheus has been added to the 'services' for monitoring
- Service nodes can now we deployed in the public subnet to run services
- Clusters deployed in Azure can have DNS in AWS (Route53)
- Azure deployments can now use images without plan (free)
- The VPC/VNET names can be specified in the config file
- The UI access can now be public or internal only
- The tags for the resources can be specified in the config file
### Changed
- Python code is refactored with OOP design
- moving keywords 'rack_aware', 'redis_distro' from network section to the 
  'clusters' section
- rebooting Redis cluster nodes in post-provisioningto clear yum locks
- Removing ssh tunneling between clusters of diffeent cloud providers
- Security groups in Azure are now associated to the subnets intead of NICs
- The internet gateway was removed for the private subnets and replaced by
  NAT gateways (egress) and a network load balancer on port 53/udp for
  ingress DNS traffic. This is for tightening security. AWS and Azure only.
- For Azure, the service principal can now use a certificate or a password and
  theuser/password can be set through environment variables as an alternative
  to the config file

## [0.9.0] - Unreleased
### Added
- Support for Azure was added, including DNS, rack awareness, exporting the GUI
  through a load balancer and peering the VNETs.
- A new config.yaml.azure file has been added as an example for Azure deployments
- The code has been restructured
- Unit tests have been added

## [0.8.4] - Unreleased
### Added
- VPC peering has been added to GCP. Although GCP is able to span a single VPC across
  regions we implemented a solution comparable to AWS where each "network" in the
  config file is its own VPC. Therefore, it is required to peer multiple VPCs
  even for GCP. Just like AWS we use the "peer_with" flag for GCP
- For GCP the name of the project can now be specified under the "network" section
  using the flag "project" and is no longer hard-coded
### Changed
- AWS credentials do not have to be set as environment variables. In case of
  a deployment outside AWS they are irrelevant.
### Fixed
- remove CIDRs "130.211.0.0/22" and "35.191.0.0/16" for access to private subnets

## [0.8.3] - Unreleased
### Added
- VPC peering has been added to AWS. This is necessary because VPC's cannot span regions 
  in AWS. To accomplish peering, the "peer_with" flag is now available in the "network" section. 
  Its value is a list of all VPC names which should be peered.
- The Web-based GUI (SM) is now available for AWS too. Simply set the flag "expose_ui" to 
  "True" in the "clusters" section of "config.yaml" file.
### Fixed
- The GCP platform now uses session affinity for the load balancer, i.e. there should
  no longer be permanent password requests when using the GUI

## [0.8.2]
### Changed
- Changed to download redislabs ansible from gcs
- Changed to default nameserver provider to network provider if not provided

## [0.8.1] - Unreleased
### Added
- A new section called 'nameservers' has been added to automate the setup of
  DNS records for the new cluster(s). This new
  section supports 3 keys. "parent_zone" is the name of the zone. The zone
  is expected to exist already and won't be created or destroyed! Second keyword 
  is "provider". Please take into account that this is not neccessarily the provider where
  the cluster was created but the provider that is hosting the DNS domain for
  the cluster. Third keyword is domain.  This value specifies the subdomain where the
  FQDN of the cluster will be created.  The resulting FQDN is
  DEPLOYMENT_NAME-CLUSTER_VPC-DOMAIN
- Added the ability to specify a config file using the config environment variable
 
### Changed
- The output of the script bin/post_provision.sh is now directed to stdout 
  as well as to the post_provision.out file on the bastion node(s)

## [0.8.0] - 2021-08-13
### Added
- In the 'clusters' section of config.yaml the OS image for the cluster nodes
  can now be specified with "machine_image"
- In the 'networks' section of config.yaml the OS image for the bastion node
  can now be specified with "bastion_machine_image" 
- In the 'networks' section of config.yaml the machine type for the bastion node
  can now be specified with "bastion_machine_type"
- In the 'networks' section of config.yaml the URL for the Redis distribution
  can now be specified with "redis_distro"
- AWS does not support subnets across availability zones (AZ) which had forced 
  us to locate the cluster in one AZ. to overcome this limit, an new keyword has 
  been introduced in the 'networks' section of config.yaml named "private_cidr". 
  This is a dictionary/map/hash with keys being the AZs and values being the 
  CIDR of the respective subnets. This applies ONLY to AWS, not GCP!!!
- The OS upgrade, Ansible/git installation and Ansible activities have been
  moved from terraform to a new bash script (bin/post_provision.sh) which 
  allows these steps to be OS-independent (i.e. various OS images can be
  used for the bastion node). The small script currently implements only the 
  RHEL and CentOS releases but will be extended soon to cover the Redis
  supported OS versions.
- All Redis cluster nodes will alo get a public IP address. This is 
  currently required for a proper DNS setup where the nameservers must be
  able to reach the nodes with the FQDN delegation. These nodes must
  be reachable from the resolver.
### Changed
- new config.yaml provided making use of the new functionalities introduced
### Removed
- The 'zone' key in the 'networks' section of the config.yaml file was removed 
  as it got replaced by the "private_cidr" functionality (one subnet per AZ)
### Fixed
- The IP address for the AWS bastion node was hard-coded as 10.0.1.50. This
  is now fixed
- We no longer use the ec2-user by default as login account for the AWS
  bastion node. To be consistent, the user "redislabs" is used for AWS
  as well as GCP
  
