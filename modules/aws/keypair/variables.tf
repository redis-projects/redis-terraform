variable "name" {
  description = "Project name, also used as prefix for resources"
  type        = string
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
}
