variable "name" {
  description = "Project name, also used as prefix for resources"
  type        = string
}

variable "subnet" {
  description = "list of subnets"
  type        = list
}

variable "zones" {
  description = "Availability zone"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security groups to attached to the node"
  type        = list(string)
}

variable "ami" {
  description = "AWS EC2 machine image"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ssh_key_name" {
  description = "AWS EC2 Keypair's name"
  type        = string
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
}

variable "redis_user" {
  description = "Redis linux user"
  type        = string
}

variable "worker_count" {}

variable "resource_tags" {
  description = "hash with tags for all resources"
}


