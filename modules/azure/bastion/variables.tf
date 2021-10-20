variable "name" {
  description = "Combined name of the deployment and VPC: <DEPLOYMENT>-<VPC>"
  type        = string
}
variable "region" {
  description = "Region for the VCP/VNET deployment"
  type        = string
}
variable "resource_group" {
  description = "Azure resourcegroup for the deployment"
  type        = string
}

variable "public_subnet_id" {
  description = "Object for the public subnet"
  type        = string
}

variable "public_secgroup" {
  description = "list of security group IDs for the public subnet"
  type        = list
}

variable "bastion_machine_type" {
  description = "Hardware type bastion node"
  type        = string    
}

variable "os" {
  description = "Machine image (OS)"
  type        = string    
}

variable "ssh_user" {
  description = "root user for bastion node"
  type        = string
}

variable "ssh_pub_key_file" {
  description = "Public key of the Bastion root user"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
}

variable "inventory" {
  description = "Inventory file of Redis Cluster nods for Ansibleplaybooks"
}

variable "extra_vars" {
  description = "Extra variables set for Ansible playbooks"
}

variable "active_active_script" {
  description = "Content of the script to setup n active-active cluster"
}

variable "ssh_private_key_file" {
  description = "Private SSH key for transferring files to the bastion"
  type        = string
}

variable "redis_distro" {
  description = "URL for the redis enterprise tarball to download from"
  type        = string    
}

