variable "kube_worker_machine_count" {}
variable "kube_worker_machine_type" {}
variable "kube_worker_machine_image" {}
variable "subnet" {}
variable "gce_ssh_user" {}
variable "gce_ssh_pub_key_file" {}
variable "boot_disk_size" {}
variable "name" {}
variable "zones" {
  description = "Availability zone"
  type        = list
}
variable "resource_tags" {
  description = "hash with tags for all resources"
}
