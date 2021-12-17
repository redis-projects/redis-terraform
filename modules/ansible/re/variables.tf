variable "ssh_user" {
  description = "User to ssh into"
  type        = string
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key"
  type        = string
  sensitive   = true
}

variable "inventory" {
  description = "Redis enterprise inventory"
  default     = ""
}

variable "extra_vars" {
  description = "Redis enterprise extra variables"
  default     = ""
}

variable "host" {
    description = "Bastion host"
}

variable "redis_distro" {
  description = "Redis distribution"
  type        = string
}

#variable "cluster_fqdn" {
#    type = list(string)
#}
#variable "other_bastions" {
#    type = list(string)
#}

#variable "other_ssh_users" {
#    type = list(string)
#}


#variable "ssh_keys" {
#    type = list(string)
#}

#locals {
#  ssh_tunnels = "${length(var.cluster_fqdn)!= 0 ? formatlist("ssh -o \"StrictHostKeyChecking no\" -L 0.0.0.0:9443:%s:9443 -L 0.0.0.0:12000:%s:12000 -N -f -i %s %s@%s", var.cluster_fqdn, var.cluster_fqdn, var.ssh_keys, var.other_ssh_users,var.other_bastions):["ls"]}"
#}
