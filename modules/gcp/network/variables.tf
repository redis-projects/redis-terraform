variable "name" {}
variable "gce_public_subnet_cidr" {}
variable "gce_private_subnet_cidr" {}
variable "region" {}
variable "cidr_list" {
  description = "List of CIDRs to allow traffic from on all ports (i.e. all VPC peers)"
  type        = list
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
