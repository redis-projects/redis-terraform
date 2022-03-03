variable "name" {
  description = "Combined name of the deployment and VPC: <DEPLOYMENT>-<VPC>"
  type        = string
}

variable "instances" {
  description = "List of private IP addresses of the Redis cluster nodes"
  type = list
}

variable "region" {
  description = "Region for the VCP/VNET deployment"
  type        = string
}

variable "resource_group" {
  description = "Azure resourcegroup for the deployment"
  type        = string
}

variable "vnet" {
  description = "ID of th virtul network (aka vpc)ß"
  type        = string
}

variable "ui_subnet" {
  description = "UI subnet object"
}