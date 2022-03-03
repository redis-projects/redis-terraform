variable "name" {}

variable "vpc_name" {
  description = "Name of this VPC"
  type        = string
}

variable "resource_name" {
  description = "Name to be given to the VPC"
  type        = string
}
variable "gce_public_subnet_cidr" {}
variable "gce_private_subnet_cidr" {}
variable "region" {}
variable "cidr_list" {
  description = "List of CIDRs to allow traffic from on all ports (i.e. all VPC peers)"
  type        = list
}

variable "ui_cidr" {
  description = "CIDR blocks for private UI Load balancers"
  type        = string
}

variable "vpc_request_list" {
  description = "List of VPC IDs which we want o request the peering for"
  type        = list
}

variable "vpc_accept_list" {
  description = "List of VPC IDs which we want to accept the peering for"
  type        = list
}

variable "resource_tags" {
  description = "hash with tags for all resources"
}

variable "vpn_list" {
  description = "List of VPC/VNETs which are connected via VPN"
  type        = list
}
variable "gcp_azure_vpns" {
  description = "List of objects for peered Azure networks"
  type        = list
}

variable "aws_vpns" {
  description = "List of objects for peered AWS networks"
  type        = list
}

variable "private_subnet_list" {
  description = "List of CIDR from VPN peers"
  type        = list
}
