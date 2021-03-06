variable "name" {
  description = "Project name, also used as prefix for resources"
  type        = string
}

variable "resource_name" {
  description = "Name to be given to the VPC"
  type        = string
}

variable "vpc_name" {
  description = "VPC name (no project prefix)"
  type        = string
}

variable "resource_tags" {
  description = "hash with tags for all resources"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR blocks for the public subnets in each zone"
  type        = map
}

variable "private_subnet_cidr" {
  description = "CIDR blocks for the private subnet in each zone"
  type        = map
}
variable "lb_subnet_cidr" {
  description = "CIDR blocks Load Balancer subnets in each zone"
  type        = map
}

variable "ui_cidr" {
  description = "CIDR blocks for private UI Load balancers"
  type        = map
}

variable "availability_zone" {
  description = "Default availability zone"
  type        = string
}

variable "peer_request_list" {
  description = "List of VPC names which we want o request the peering for"
  type        = list
}

variable "peer_accept_list" {
  description = "List of VPC names which we want to accept the peering for"
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

variable "region_map" {
  description = "Hash where the region for each VPC name is stored"
  type        = map
}

variable "cidr_map" {
  description = "Hash where the CIDR for each VPC name is stored"
  type        = map
}

variable "vpn_list" {
  description = "List of VPC/VNETs which are connected via VPN"
  type        = list
}

variable "private_subnet_list" {
  description = "List of private subnet CIDRs of VPN networks"
  type        = list
}

variable "vpc_conn_index" {
  description = "List of connection indexes to be accepted"
  type        = list
}

variable "gcp_azure_vpns" {
  description = "list of peered VPN objects"
  type        = list
}
