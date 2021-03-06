variable "zone" {}
variable "name" {}
variable "gce_public_subnet_cidr" {}
variable "gce_private_subnet_cidr" {}
variable "region" {}
variable "bastion_machine_type" {}
variable "os" {}
variable "boot_disk_size" {}
variable "subnet" {}
variable "gce_ssh_user" {}
variable "gce_ssh_pub_key_file" {}
variable "resource_tags" {
  description = "hash with tags for all resources"
}