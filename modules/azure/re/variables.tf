variable "name" {
  description = "Combined name of the deployment and VPC: <DEPLOYMENT>-<VPC>"
  type        = string
}

variable "vpc" {
  description = "The VPC/VNET"
  type        = string
}
variable "region" {
  description = "Region for the VCP/VNET deployment"
  type        = string
}

variable "resource_tags" {
  description = "hash with tags for all resources"
}

variable "resource_group" {
  description = "Azure resourcegroup for the deployment"
  type        = string
}

variable "private_subnet_id" {
  description = "Object for the private subnet"
  type        = string
}

variable "private_secgroup" {
  description = "list of security group IDs for the private subnet"
  type        = list
}

variable "machine_type" {
  description = "Hardwaretype for Redis cluster nodes"
  type        = string
}

variable "machine_plan" {
  description = "Azure OS Image plan (Marketplace)"
  type        = string
}

variable "machine_count" {
  description = "number of Redis cluster nodes to be deployed"
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

variable "zones" {
  description = "Availability zone"
  type        = list
}
