variable "name" {
  description = "Combined name of the deployment and VPC: <DEPLOYMENT>-<VPC>"
  type        = string
}

variable "expose_ui" {
  description = "Boolean to tell if the GUI port should be exposed"
  type        = bool
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC/VNET"
  type        = string
}
variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  type        = string
}
variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
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

variable "vpc_request_list" {
  description = "List of VPC IDs which we want to request the peering for"
  type        = list
}

variable "vpc_accept_list" {
  description = "List of VPC IDs which we want to accept the peering for"
  type        = list
}