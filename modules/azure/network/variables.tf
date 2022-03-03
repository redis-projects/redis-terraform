variable "name" {
  description = "Combined name of the deployment and VPC: <DEPLOYMENT>-<VPC>"
  type        = string
}

variable "vnet_name" {
  description = "Name of this VNET"
  type        = string
}

variable "resource_name" {
  description = "Name to be given to the VNET"
  type        = string
}

variable "resource_tags" {
  description = "hash with tags for all resources"
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

variable "ui_cidr" {
  description = "CIDR blocks for private UI Load balancers"
  type        = string
}

variable "gateway_subnet_cidr" {
  description = "CIDR for the VPN gateway subnet"
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

variable "vpn_list" {
  description = "List of VPC/VNETs which are connected via VPN"
  type        = list
}
variable "gcp_azure_vpns" {
  description = "List of objects for peered GCP networks"
  type        = list
}

variable "aws_vpns" {
  description = "List of objects for peered AWS networks"
  type        = list
}
