variable "name" {
  description = "Project name, also used as prefix for resources"
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
  description = "CIDR block for the private subnet 1"
  type        = string
}

variable "availability_zone" {
  description = "Default availability zone"
  type        = string
}
