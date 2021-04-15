
variable "vpc" {}
variable "random_id" {}
variable "gce_public_subnet_cidr" {}
variable "gce_private_subnet_cidr" {}
variable "region" {}
variable "bastion_machine_type" {}
variable "os" {}
variable "boot_disk_size" {}
variable "public_subnet_name" {}
variable "gce_ssh_user" {}
variable "gce_ssh_pub_key_file" {}
variable "inventory" {}
variable "gce_ssh_private_key_file" {}
variable "extra_vars" {}
variable "redis_distro" {}
variable "ansible_repo_creds" {}