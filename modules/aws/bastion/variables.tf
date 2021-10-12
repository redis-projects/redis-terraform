variable "name" {
  description = "Project name, also used as prefix for resources"
  type        = string
}

variable "vpc" {
  description = "vpc id for bastion"
  type        = string
}

variable "availability_zone" {
  description = "Default availability zone"
  type        = string
}

variable "subnet" {
  description = "Id of the subnet, to which this bastion belongs"
  type        = string
}

variable "security_groups" {
  description = "List of security groups to attached to the bastion"
  type        = list(string)
}

#variable "igw" {
#  description = "Internet gateway entity"
#}

variable "ami" {
  description = "AWS EC2 machine image"
  type        = string
}

variable "instance_type" {
  description = "AWS EC2 instance type"
  type        = string
}

variable "ssh_key_name" {
  description = "AWS EC2 Keypair's name"
  type        = string
}

variable "redis_user" {
  description = "Redis linux user"
  type        = string
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
}
variable "cluster_fqdn" {
    type = list(string)
}
variable "other_bastions" {
    type = list(string)
}

variable "other_ssh_users" {
    type = list(string)
}


variable "ssh_keys" {
    type = list(string)
}

locals {
  ssh_tunnels = "${length(var.cluster_fqdn)!= 0 ? formatlist("ssh -o \"StrictHostKeyChecking no\" -L 0.0.0.0:9443:%s:9443 -L 0.0.0.0:12000:%s:12000 -N -f -i %s %s@%s", var.cluster_fqdn, var.cluster_fqdn, var.ssh_keys, var.other_ssh_users,var.other_bastions):["ls"]}"
}
