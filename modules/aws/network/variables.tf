variable "name" {
  description = "Project name, also used as prefix for resources"
  type        = string
}

variable "vpc_name" {
  description = "VPC name (no project prefix)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet 1"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR blocks for the private subnet in each zone"
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

variable "vpc_conn_index" {
  description = "List of connection indexes to be accepted"
  type        = list
}
