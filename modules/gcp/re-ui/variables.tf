variable "name" {}
variable "instances" {
  type = list
}
variable "zones" {
  type = list
}

variable "resource_tags" {
  description = "hash with tags for all resources"
}

variable "ui_subnet" {
  description = "UI subnet object"
}