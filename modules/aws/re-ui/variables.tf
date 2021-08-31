variable "name" {
  description = "Name of the deployment"
  type        = string
}

variable "ips" {
  description = "List of IP addreses"
  type        = list
}

variable "subnets" {
  description = "List of subnets"
  type        = list
}

variable "vpc" {
  description = "ID of the VPC"
  type        = string
}
