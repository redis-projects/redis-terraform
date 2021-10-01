variable "zone" {}
variable "vpc" {}
variable "random_id" {}
variable "gce_public_subnet_cidr" {}
variable "gce_private_subnet_cidr" {}
variable "region" {}
variable "bastion_machine_type" {}
variable "os" {}
variable "boot_disk_size" {}
variable "subnet" {}
variable "gce_ssh_user" {}
variable "gce_ssh_pub_key_file" {}
variable "inventory" {}
variable "active_active_script" {}
variable "gce_ssh_private_key_file" {}
variable "extra_vars" {}
variable "redis_distro" {}
variable "cluster_fqdn" {
    type = list(string)
}
variable "other_bastions" {
    type = list(string)
}

variable "other_ssh_users" {
    type = list(string)
}
locals {
  ssh_tunnels = "${length(var.cluster_fqdn)!= 0 ? formatlist("ssh -L 9443:%s:9443 -L 12000:%s:12000 %s@%s", var.cluster_fqdn, var.cluster_fqdn, var.other_ssh_users,var.other_bastions):["ls"]}"
}
